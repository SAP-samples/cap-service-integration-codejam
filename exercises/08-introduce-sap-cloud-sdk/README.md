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

### Looking at the root cause of the error

What's happening is that CAP's remote service codebase is invoked because of this new line:

```js
const S4bupa = await cds.connect.to('API_BUSINESS_PARTNER')
```

which, due to its position in the generally exported module defined in `srv/incident-service.js`, is executed during the server startup (as the implementation for the service defined in `srv/incident-service.cds`) and libraries & functions required for remote service connectivity are loaded. The [@sap-cloud-sdk/resilience](https://www.npmjs.com/package/@sap-cloud-sdk/resilience) module is required, to provide a timeout mechanism for managing remote API calls that may not return, for example.

In fact, CAP uses the SAP Cloud SDK to perform the "heavy lifting" of activities in this remote connectivity area.

Back when we [imported the API specification](../03-import-odata-api#import-the-api-specification), extra entries were added to the `dependencies` section of `package.json` in addition to a new `cds.requires` section for the `API_BUSINESS_PARTNER` remote service:

```json
{
  "dependencies": {
    "@sap/cds": "^8",
    "express": "^4",
    "@sap-cloud-sdk/connectivity": "^3",
    "@sap-cloud-sdk/http-client": "^3",
    "@sap-cloud-sdk/resilience": "^3"
  }
}
```

These extra entries are SAP Cloud SDK packages, and when we stop to think about it, it makes sense that these are automatically added when we're setting up a remote service requirement. One of those packages is indeed that which the error is mentioning, too: `@sap-cloud-sdk/resilience`.

👉 Install the required packages with `npm add`, and then check what's installed with `npm list`, which should produce something that looks like this:

```text
@acme/incidents-mgmt@1.0.0 /workspaces/cap-service-integration-codejam/incidents
├── @cap-js/sqlite@1.11.0
├── @sap-cloud-sdk/connectivity@3.26.4
├── @sap-cloud-sdk/http-client@3.26.4
├── @sap-cloud-sdk/resilience@3.26.4
├── @sap/cds@8.9.4
└── express@4.21.2
```

Great!

### Get going again

👉 Once the modules have been installed, start the main CAP server up one more time, but this time, specify the value `remote` for the `DEBUG` environment variable, so that the CAP server will emit extra information on remote service activities:

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
