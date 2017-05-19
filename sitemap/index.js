/******************************************************************************
 *
 * Specialisation of a more general script to change links to static pages into
 * ones that dynamically generate the corresponding page. This variant focuses
 * on downloading a sitemap JSON and make only the /index.html dynamic.
 * 
 * Assumes `localStorage && XMLHttpRequest && JSON && addEventListener` and
 * that `DOMContentLoaded` and `popstate` are valid events. Browsers in which
 * JavaScript is disabled and ones that don't support one of the prerequisites
 * will simply see the link to the static page.
 *
 * [ To test locally on Chromium, do --allow-file-access-from-files. ]
 *****************************************************************************/

/* Defines *******************************************************************/

/** @define {string} */ var INDEX = "/index.html"; // Link to static HTML index
/** @define {string} */ var SITEMAP = "/sitemap.json"; // Link to JSON
/** @define {number} */ var EXPIRATION = 2<<22; // 2²²ms ≈ 3h

/* Globals *******************************************************************/

var /** Object<string,Array<Node>> */ pages = {},
    /** string */ original,
    /** string */ current = original = window.location.pathname,
    /** string */ host = window.location.host;

/* Logic *********************************************************************/

/**
 * Constructs a DOM node with attributes and children DOM nodes.
 *
 * @param {string} tag                     : Tag of the DOM node.
 * @param {Object<string, ?string>} attrs  : HTML attributes. Will be included
                                             unless null-valued.
 * @param {Array<?(Node|string)>} children : Text or element nodes are added as
 *                                           children, and null values skipped.
 * @returns {Node}                         : Resulting DOM node.
 */
function element(tag, attrs, children){
    var result = document.createElement(tag), attr;
    for(var i in attrs)
        if(attr = attrs[i])
            result.setAttribute(i, attr);
    for(var i = 0, l = children.length, c; i<l;)
        if(c = children[i++])
           result.appendChild(typeof c=="string"?document.createTextNode(c):c);
    return result;
}



/**
 * Constructs a DOM unordered list node representing a table of contents, from
 * an array of objects containing information about the title (t), link (p),
 * description (a), visibility (h) and subheaders (c) of each entry in the ToC.
 *
 * @param {Array<Object>} entries : ToC information.
 * @returns {Node}                : <UL> node representing the ToC.
 */
function list(entries){
    if(!entries)
        return null;
    
    var items = [];
    for(var entry, i = 0, l = entries.length; i<l; i++)
        if(!(entry = entries[i])["h"]) {
            var anchor = element(entry["p"] ? "a" : "span",
                {
                    "href": entry["p"],
                    "title": entry["a"]
                },
                [ entry["t"] || guess_title(entry["p"]) ]
            );

            items.push(
                element("li",
                    {
                        "class": anchor.pathname == original && "selected"
                    },
                    [ anchor, list(entry["c"]) ]
                ),
                "\n" // For correct li spacing
            );
        }
    return element("ul", {}, items);
}



/**
 * Change the anchor nodes within a node, in such a way that activating one
 * generates the dynamic page counterpart of the original link, if available.
 * Does not work when the hash or query part of the link is non-empty.
 *
 * @param {Node} node : The anchor or node whose anchors are to be routed.
 * @return {undefined}
 */
function route(node){
    var tag = node.tagName;
    
    if(tag == "A"){
        var path = node.pathname;
        if(pages[path] && !node.hash.substr(1) && node.host == host){
            node.onclick = function(){
                return !follow(path);
            }
            if(path != original)
                node.href = "#" + path
        }
    }
    else if(tag)
        for(
            var anchor, i = 0, anchors = node.getElementsByTagName("a");
            anchor = anchors[i++];
        )
            route(anchor);
}



/**
 * Replace the contents of the <BODY> with the DOM content associated with a
 * given `path`.
 * 
 * @param {string} path : The path to the static page.
 * @return {boolean}    : Whether the path could be followed to a dynamic page.
 */
function follow(path){
    var content = pages[path];
    
    if(content && current != path){
    
        // Prevent state change from making us follow the same path twice
        current = path; 

        // Save scroll state
        var body = document.body,
            doc = (body.scrollTop > 0) ? body : document.documentElement;
        content.scroll = doc.scrollTop;

        // Delete and replace document.body
        for(var n; n = body.firstChild; body.removeChild(n)){}
        for(var n, i = 0; n = content[i++];) body.appendChild(n);

        // Change hash to reflect this change
        window.location.hash = path == original ? "" : "#" + path;

        // Restore scroll state
        doc.scrollTop = content.scroll;
    }
    return !!content;
}



/**
 * Prepare for processing, by downloading or retrieving from cache a JSON
 * structure that describes a table of contents. Does process() upon success.
 * 
 * @return {undefined}
 */
function prepare(){
    var storage = localStorage,
        now = (new Date()).getTime(),
        recent = storage.getItem("ms");
    
    if(!recent || now - recent > EXPIRATION){
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function(){
            if (xhr.readyState == 4 && (xhr.status == 200 || xhr.status == 0)){
                var json = xhr.responseText;
                storage.setItem("map", json);
                storage.setItem("ms", now);
                process(json);
            }
        };
        xhr.open("GET", ROOT + SITEMAP + "?t=" + now, true);
        xhr.send();
    }
    else process(storage.getItem("map"));
}



/**
 * Guess a page title from its page name.
 *
 * @param {string} path : Path to file
 * @return {string}
 */
function guess_title(path){
    return path.split(/[\\/]/).pop();
}



/**
 * 1. Populate the global `pages` object with the DOM elements appropriate for
 *    each path, as constructed from the data present in the current page and
 *    given JSON.
 * 2. Enhance every anchor element with JavaScript functions.
 * 3. Redirect to the correct dynamic page if necessary.
 * 
 * @throws {SyntaxError}
 * @param {string} raw : Plain-text JSON describing the index page.
 * @return {undefined}
 */
function process(raw){
    var json = JSON.parse(raw);

    // Populate object containing the original page
    var nodes = [];
    for(var node = document.body.firstChild; node; node = node.nextSibling)
        nodes.push(node);
    pages[original] = nodes;

    // Populate onject containing the generated index
    pages[INDEX] = [
        element("nav", {"class": "up"}, [
            element("div", {}, [list(json[0])]),
            element("footer", {}, [list(json[1])])
        ])
    ];

    // Install routes into page
    for(var path in pages)
        for(var j = 0, node, content = pages[path]; node = content[j++];)
            route(node);

    // Redirect
    follow_hash();
}



/**
 * Read the hash in the address bar and open the corresponding page, if any.
 *
 * @return {undefined}
 */
function follow_hash(){
    follow(window.location.hash.substr(1)) || follow(original);
}



/* Running *******************************************************************/

if(document.readyState === "complete")
    prepare();
else
    document.addEventListener("DOMContentLoaded", prepare);

window.addEventListener("popstate", follow_hash);
