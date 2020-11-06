

// defining a resource
resource = _ comment:description? _ future:"future"? _ singleton:"singleton"? _ type:("configuration-resource" / "asset-resource" / "resource" / "request-resource") _ respath:noparentrespath _ "{" _
    attributes:attributes? _ requestHeaders:requestHeaders? _ eventsAndOps:eventsAndOperationsAnyOrder _
"}" _ ";"? _ {
    return {
        category: "definition",
        kind: "resource-like",
        comment: comment, future: !!future, singleton: !!singleton, type: type,
        attributes: attributes, operations: eventsAndOps.ops, events: eventsAndOps.events,
        requestHeaders: requestHeaders,
        parents: [], short: respath.short}
}

// TODO figure out how we want to order the request-headers section
eventsAndOperationsAnyOrder =
  _ o:operations _ e:events? {return {events: e, ops: o}} /
  _ e:events _ o:operations? {return {events: e, ops: o}} /
  _ {return {events: null, ops: null}}

subresource = _ comment:description? _ future:"future"? _ singleton:"singleton"? _ type:("subresource") _ respath:parentrespath _ "{" _
    attributes:attributes? _ operations:operations? _ events:events? _
"}" _ ";"? _ {
    return {
        category: "definition",
        kind: "resource-like",
        comment: comment, future: !!future, singleton: !!singleton, type: type,
        attributes: attributes, operations: operations, events,
        parents: respath.parents, short: respath.short}
}

action = _ comment:description? _ future:"future"? _ async:("sync"/"async") _ bulk:("bulk" / "resource-level")? _ "action" _ respath:parentrespath _ "{" _
    attributes:attributes? _ operations:operations? _ events:events? _
"}" _ ";"? _ {
    return {
        category: "definition",
        kind: "resource-like",
        comment: comment, future: !!future, singleton: false, type: "action", async: async == "async",
        attributes: attributes, operations: operations, events,
        parents: respath.parents, short: respath.short,
        bulk: bulk}
}

operations = _ "/operations" _ ops:operation+ _ {
    return ops;
}

operation = _ operation:ops _ errors: errors* _ ";"? _ {
    operation.errors = errors;
    return operation
}

events = _ "/events" _ ops:eventops+ _ {
    return ops;
}

//TODO rename this new stuff vvv
requestHeaders = _ "/request-headers" _ operationsAndHeaders:operationOrWildcard* _ {
    return operationsAndHeaders;
}

operationOrWildcard =
  opOrWildcard:(oplist / "*" ) _ headerObjName:name _ {
    return {opOrWildcard: opOrWildcard, headerObjName: headerObjName}
  }
//TODO rename this new stuff ^^^

errors = _ codes:errorcode+ _ struct:ref _ {
    return {codes: codes, "struct": struct}
}
errorcode = _ comment:description? _ code:[0-9]+ {
    return {"code": code.join(""), "comment": comment}
}

ops = _ comment:description? _ op:(mainops / multiops) _ options:options _ {return {"operation": op, "comment": comment, "options": options}}
eventops = _ comment:description? _ op:(mainops / ([a-z_]+[_a-z0-9]*)) _ {return {"operation": Array.isArray(op) ? op.flat().join("") : op, "comment": comment}}
oplist = op:("GET" / "MULTIGET" / "PUT" / "MULTIPUT" / "PATCH" / "MULTIPATCH" / "POST" / "MULTIPOST" / "DELETE"/ "MULTIDELETE") {
    return op
}
mainops = op:("GET" / "PUT" / "PATCH" / "POST" / "DELETE") {
    return op
}
multiops = op:("MULTIGET" / "MULTIPUT" / "MULTIPATCH" / "MULTIPOST" / "MULTIDELETE") {
    return op
}
options = options:option* {
    return options
}
option = _ name:[a-z_\-]+ _ "=" _ value:[a-zA-Z0-9_\-]+ _ {
    return {name: name.join(""), value: value.join("")}
}

ids "ids" = ids:id+ {return ids}
id "id" = _ name:name _ ","? _ {return name}

httpHeader = _ comment:description? _ type:("http-header")  _ name:name  _ "{" _
    "name:" _ headerName:[a-zA-Z0-9\-]+ _
"}" _ ";"? _ {
    return {category: "definition", kind: type, "type": type, parents: [], "short": name, "comment": comment, "headerName": headerName.join("")}
}
