# Exercise 08 - Introduce the SAP Cloud SDK

At the end of this exercise, we'll have moved very close to connecting to a real external system for our imported `API_BUSINESS_PARTNER` service.

## Move the mocking of API_BUSINESS_PARTNER to a separate process

To start on that journey, let's first move away from the in-process mocking that the CAP server provides out of the box for us. We did this already in [exercise 06](../06-mock-separate-process/) so it shouldn't take long to get set up again.

👉 Begin by terminating the currently running CAP server (that is probably still running from the previous exercise, having been started with `cds watch`).

### Start mocking the external service

👉 In one terminal, start up the separate mocking of the `API_BUSINESS_PARTNER` service like you did in exercise 06:

```bash
cds mock API_BUSINESS_PARTNER --port 5005
```

If you now visit <http://localhost:5005> you'll see the service endpoint at `/odata/v4/api-business-partner` being served, i.e. the external service. You can still access the three CSV-supplied records in the `A_BusinessPartner` entity set (<http://localhost:5005/odata/v4/api-business-partner/A_BusinessPartner>).

### Start serving your main service

👉 In a second terminal, start up the main service as before:

```bash
cds watch
```

As before, you should observe that if you visit <http://localhost:4004> you'll see the service endpoint at `/odata/v4/incidents` being served, i.e. your main service.

👉 Notice that as before there's a `Customers` entity set available in the service. Try to access it (at <http://localhost:4004/odata/v4/incidents/Customers>).

You should see a similar message to what we encountered in [exercise 04 where we took a naïve approach to incorporating the external service](../04-understand-service-mocking/README.md#take-a-naïve-approach-to-incorporating-the-external-service):

```text
Entity "IncidentsService.Customers" is annotated with "@cds.persistence.skip" and cannot be served generically.
```

"_But wait!_", I hear you say. "_Didn't we solve that issue by using mocking, and aren't we mocking now?_"

Yes.

But.

This time, the mocking of the external service is no longer in-process based mocking. It's being mocked in an external process (started separately with `cds mock API_BUSINESS_PARTNER --port 5005`). This is more realistic, and brings about a context that makes it harder for the CAP server to guess what it should automatically do when data is requested.

So it doesn't attempt to, and instead, gently suggests that you have to do it.

So let's do it!

## Provide a handler for delegating calls to the remote system

We need to provide a handler in the context of our main incidents service to take appropriate action (retrieve the data from the remote service) when READ requests for the `Customers` entity are encountered. CAP has told us it is not going to attempt this generically and implicitly for us, because it's no longer a simple in-process connection, but a more real external (HTTP and OData based) connection that's needed.

We can do this by creating a simple service implementation, in the `srv/incidents-service.js` file. 

> The fact that this filename has the same base as the `srv/incidents-service.cds` file is no coincidence; it's just another example of CAP's lovely convention over configuration - read more about it in the link in the [Further reading](#further-reading) section below.


### Stop the main CAP server process

👉 Before proceeding, use Ctrl-C to stop the main CAP server process. Not the one that's mocking `API_BUSINESS_PARTNER` (leave that one running), but the one that is serving your main service and has just emitted the error.

### Add the handler code

This `srv/incidents-service.js` file is ready and waiting for our handlers, and currently looks like this:

```js
const cds = require('@sap/cds');

module.exports = cds.service.impl (async function() {

})
```

> There's also the ES6 class based approach to creating the context for a service implementation, but to keep things simple, we'll take the `cds.service.impl` approach here. See the [Further reading](#further-reading) for a link to how to provide service implementations.

👉 Inside the anonymous function (i.e. inside the `{ ... }` block), add the following:

```js
    const S4bupa = await cds.connect.to('API_BUSINESS_PARTNER')

    this.on('READ', 'Customers', (req) => {
      console.log('>> delegating to remote service...')
      return S4bupa.run(req.query)
    })
```

Let's walk through this code at a high level. 

As a result of the `cds.connect.to('API_BUSINESS_PARTNER')` call, the `S4bupa` constant will contain a connection object that can be used for remote communication with the service specified (i.e. with `API_BUSINESS_PARTNER`), based on whatever information is in the corresponding `cds.requires` section of the configuration loaded at runtime.

We're currently mocking that service, and we can see the details that will be available at runtime in the `~/.cds-services.json` file that we've looked at in previous exercises. In fact, because the `cds mock API_BUSINESS_PARTNER --port 5005` process is still running, that file contains, right now, information that looks like this:

```json
{
  "cds": {
    "provides": {
      "API_BUSINESS_PARTNER": {
        "kind": "odata",
        "credentials": {
          "url": "http://localhost:5005/odata/v4/api-business-partner"
        },
        "server": 9660
      }
    },
    "servers": {
      "9660": {
        "root": "file:///home/user/projects/cap-service-integration-codejam/incidents",
        "url": "http://localhost:5005"
      }
    }
  }
}
```

In other words, the connection object will essentially point to `http://localhost:5005/odata/v4/api-business-partner`.

> The beauty of this approach is that connection information remains abstract and separate from the service implementation, which is especially important when moving across tiered landscapes and also to protect credentials and manage their lifecycle separately.

Continuing to look through the code in `srv/incidents-service.js`, this connection object is then used, when handling the `READ` event for the `Customers` entity, to relay the actual request (in `req.query`) to the remote system (via `S4bupa.run()`). The response to this remote request is then returned to the original requester (i.e. the request that invoked this `READ` event in the first place).

### Try it out

👉 Now, while leaving the `cds mock API_BUSINESS_PARTNER --port 5005` still running, restart the main CAP server process:

```bash
cds watch
```

A rather severe message appears, yikes! Here's a slightly reduced version:

```text
❗️ ERROR on server start: ❗️

 Error: Cannot find module '@sap-cloud-sdk/resilience'
Require stack:
- .../node_modules/@sap/cds/libx/_runtime/remote/utils/cloudSdkProvider.js
- .../node_modules/@sap/cds/libx/_runtime/remote/utils/client.js
- .../node_modules/@sap/cds/libx/_runtime/remote/Service.js
```

### Analyze and fix the 'resilience' error

What's happening is that CAP's remote service codebase is invoked because of this new line:

```js
const S4bupa = await cds.connect.to('API_BUSINESS_PARTNER')
```

which, due to its position in the generally exported module defined in `srv/incident-service.js`, is executed during the server startup (as the implementation for the service defined in `srv/incident-service.cds`) and libraries & functions required for remote service connectivity are loaded. The [@sap-cloud-sdk/resilience](https://www.npmjs.com/package/@sap-cloud-sdk/resilience) module is required, to provide a timeout mechanism for managing remote API calls that may not return, for example.

👉 Fix this by adding this module to the project (making sure you're still in the `incidents/` directory):

```shell
npm add @sap-cloud-sdk/resilience
```

> `add` is just a synonym for `install` here.

### Try it out again

Then try to start the CAP server again:

```shell
cds watch
```

👉 Observe the log output, and not only does that error not occur any more, you should see something new:

```text
[cds] - connect to API_BUSINESS_PARTNER > odata { url: 'http://localhost:5005/odata/v4/api-business-partner' }
```

This indicates that the `cds.connect.to('API_BUSINESS_PARTNER')` call was now made successfully.

Note that this is just an indication that the remote connection details have been marshalled and calls to the remote system can be made as and when required. No calls have actually been made yet, as you can observe from the fact that the log output from the mocked `API_BUSINESS_PARTNER` service (in the other terminal) shows no activity.

👉 Make a request to the `Customers` entity set again via <http://localhost:4004/odata/v4/incidents/Customers>.

Whoops!

Another error.

But a slightly different one!

There's an XML based HTTP response payload with an error code (502) and a detailed message, the important part of which is this:

```text
Error during request to remote service: Cannot find module '@sap-cloud-sdk/http-client'
```

👉 Head over to the log output of the main CAP server process and take a look. You should see something like this (heavily reduced for brevity):

```text
[odata] - GET /odata/v4/incidents/Customers
>> delegating to remote service...
[remote] - Error: Error during request to remote service:
Cannot find module '@sap-cloud-sdk/http-client'
Require stack:
- .../node_modules/@sap/cds/libx/_runtime/remote/utils/cloudSdkProvider.js
- .../node_modules/@sap/cds/libx/_runtime/remote/utils/client.js
- .../node_modules/@sap/cds/libx/_runtime/remote/Service.js
request: {
  method: 'GET',
  url: '/A_BusinessPartner?$select=BusinessPartner,BusinessPartnerFullName&$orderby=BusinessPartner%20asc&$top=1000'
}
```

### Analyze and fix the 'http-client' error

Let's see what we can discern from this:

* we can see our log message (`>> delegating to remote service...`) appears directly before the error
* there's a requirement for for another SAP Cloud SDK module `@sap-cloud-sdk/http-client` (which we also haven't explicitly installed)
* there's an HTTP GET request being attempted at the time of failure
* this HTTP request is to the following relative URL (URL-decoded and with whitespace added for readability):
    ```text
    /A_BusinessPartner
    ?$select=BusinessPartner,BusinessPartnerFullName
    &$orderby=BusinessPartner asc
    &$top=1000
    ```

If you were thinking that this was the direct result of the call to `S4bupa.run(req.query)`, which in turn was the direct result of the `READ` event for `Customers` being triggered, which in turn was a direct result of you making a request to `http://localhost:4004/odata/v4/incidents/Customers`, you'd be spot on.

CAP makes significant use of the SAP Cloud SDK. Specifically for remote connectivity, the `@sap-cloud-sdk/http-client` is employed, because it handles connectivity related issues such as destination lookup, connections to SAP S/4HANA on-prem systems, web proxies, and more. This is in addition to `@sap-cloud-sdk/resilience` that we've already seen. There's a link in the [Further reading](#further-reading) section below that will take you to the SAP Cloud SDK guide.

So just like before, add this other SAP Cloud SDK module to the project.

👉 First, stop the main CAP server process again with Ctrl-C.

👉 Now add this module too:

```bash
npm add @sap-cloud-sdk/http-client
```

If you wish, you can check the modules installed for your project now with `npm ls`, which should now include these two from the SAP Cloud SDK.

In addition, note that in real life, you can mitigate these issues beforehand of course, by installing `@sap-cloud-sdk/http-client` at the outset; this will cause `@sap-cloud-sdk/resilience` to be installed too, as a dependency of `@sap-cloud-sdk/http-client`. This exercise deliberately omitted this mitigation as it's a chance for us to learn more.

You can see the difference between the output of `npm ls` right now, i.e. after installing them in the sequence described in this exercise:

```text
+-- @cap-js/sqlite@1.4.0
+-- @sap-cloud-sdk/http-client@3.11.0
+-- @sap-cloud-sdk/resilience@3.11.0
+-- @sap/cds@7.5.3
`-- express@4.18.2
```

compared to what it would be like if you'd just installed `@sap-cloud-sdk/http-client` at the outset, in which case the output of `npm ls` would look like this:

```text
+-- @cap-js/sqlite@1.4.0
+-- @sap-cloud-sdk/http-client@3.11.0
+-- @sap/cds@7.5.3
`-- express@4.18.2
```

so you'd have to increase the list depth level from the default of 0 to 1, with `npm ls --depth=1`, to see this:

```text
+-- @cap-js/sqlite@1.4.0
| +-- @cap-js/db-service@1.5.1
| +-- @sap/cds@7.5.3 deduped
| `-- better-sqlite3@9.3.0
+-- @sap-cloud-sdk/http-client@3.11.0
| +-- @sap-cloud-sdk/connectivity@3.11.0
| +-- @sap-cloud-sdk/resilience@3.11.0
| +-- @sap-cloud-sdk/util@3.11.0
| `-- axios@1.6.7
+-- @sap/cds@7.5.3
| +-- @cap-js/cds-types@0.2.0
| +-- @sap/cds-compiler@4.5.0
| +-- @sap/cds-fiori@1.2.2
| `-- @sap/cds-foss@5.0.0
`-- express@4.18.2
  +-- accepts@1.3.8
  +-- array-flatten@1.1.1
  +-- body-parser@1.20.1
  +-- ...
```

👉 Once the modules have been installed (and they will have been added to the list of `dependencies` in the project's `package.json` file), start the main CAP server up one more time, but this time, specify the value `remote` for the `DEBUG` environment variable, so that the CAP server will emit extra information on remote service activities:

```bash
DEBUG=remote cds watch
```

> Setting an environment variable like this "in-line" with a command means that it will be set for that command only. After you terminate the `cds watch` command here, the value of `DEBUG` will be whatever it was before this invocation, possibly (and probably, in the context of this exercise) nothing. See the [Further reading](#further-reading) section below for more information on the use of `DEBUG`.

👉 Re-request that `Customers` entity set at <http://localhost:4004/odata/v4/incidents/Customers>. You should now get the data, instead of the error, and it will look something like this:

```json
{
  "@odata.context": "$metadata#Customers",
  "value": [
    {
      "ID": "Z100001",
      "name": "Harry Potter"
    },
    {
      "ID": "Z100002",
      "name": "Sherlock Holmes"
    },
    {
      "ID": "Z100003",
      "name": "Sunny Sunshine"
    }
  ]
}
```

The data itself doesn't look any different. But this time, while essentially the service is still being mocked, it's being mocked in a separate process, as a proper remote service, with the requests to the data being delegated to it via real OData operations.

👉 To confirm this, look at the log output from the mocked service (the one you started in the other terminal window with `cds mock API_BUSINESS_PARTNER --port 5005`). You should see the evidence of a request:

```text
[cds] - GET /odata/v4/api-business-partner/A_BusinessPartner?$select=BusinessPartner,BusinessPartnerFullName&$orderby=BusinessPartner asc&$top=1000
```

This is indeed the same request that was attempted before, that we saw in the error message above.

👉 And in fact, if you check the log output from the serving of the main service (the one started with `cds watch`), you should see something like this (with the detailed log line prefixed "[remote]" being emitted specifically because of `DEBUG=remote`):

```text
[cds] - GET /incidents/Customers 
>> delegating to remote service...
[remote] - GET http://localhost:5005/odata/v4/api-business-partner/A_BusinessPartner?$select=BusinessPartner,BusinessPartnerFullName&$orderby=BusinessPartner%20asc&$top=1000 {
  headers: {
    accept: 'application/json,text/plain',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
    'x-correlation-id': '9ccba1c6-57ef-41e4-b2f1-1c4570916120'
  },
  data: undefined
}
```

This is a sign of a successful delegation to a remote service!

## Summary

At this point: 

* you're running your external service in a mocked but real, remote service, accessed via HTTP
* you've added handler code for the appropriate event to delegate calls to that remote service as required
* you've installed the modules from the SAP Cloud SDK to make this connectivity and remote calling possible

Great work!

## Further reading

* [How to provide service implementations](https://cap.cloud.sap/docs/node.js/core-services#how-to-provide-custom-service-implementations)
* [Mock Remote Service as OData Service (Node.js)](https://cap.cloud.sap/docs/guides/using-services#mock-remote-service-as-odata-service-node-js)
* [cds.connect.to(name, options?)](https://cap.cloud.sap/docs/node.js/cds-connect#cdsconnectto--name-options--service)
* [SAP Cloud SDK (JavaScript)](https://sap.github.io/cloud-sdk/docs/js/getting-started)
* [@sap-cloud-sdk/http-client NPM package](https://www.npmjs.com/package/@sap-cloud-sdk/http-client)
* [DEBUG env variable](https://cap.cloud.sap/docs/node.js/cds-log#debug-env-variable)

---

## Questions

If you finish earlier than your fellow participants, you might like to ponder these questions. There isn't always a single correct answer and there are no prizes - they're just to give you something else to think about.

1. When you "make a request to the `Customers` entity set again", what type of OData operation is it?

1. If you stop the mocked external service process (the one you started with `cds mock API_BUSINESS_PARTNER --port 5005`) and then make a call to the `Customers` entity set again, what happens?

---

[Next exercise](../09-set-up-remote-system-configuration/)
