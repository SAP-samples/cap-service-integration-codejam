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

If you now visit <http://localhost:5005> you'll see the service endpoint at `/api-business-partner` being served, i.e. the external service. You can still access the three CSV-supplied records in the `A_BusinessPartner` entity set (<http://localhost:5005/api-business-partner/A_BusinessPartner>).

### Start serving your main service

👉 In a second terminal, start up the main service as before:

```bash
cds watch
```

As before, you should observe that if you visit <http://localhost:4004> you'll see the service endpoint at `/incidents` being served, i.e. your main service.

👉 Notice that as before there's a `Customers` entity set available in the service. Try to access it (at <http://localhost:4004/incidents/Customers>).

You should see a similar message to what we encountered in [exercise 04 where we took a naïve approach to incorporating the external service](../04-understand-service-mocking/README.md#take-a-naïve-approach-to-incorporating-the-external-service):

```text
Entity "IncidentsService.Customers" is annotated with "@cds.persistence.skip" and cannot be served generically.
```

"But wait!", I hear you say. Didn't we solve that issue by using mocking, and aren't we mocking now?

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
module.exports = (async function() {

})
```

👉 Inside the function (i.e. in between the top and bottom lines that are in there already), add the following:

```js
    const cds = require('@sap/cds');
    const S4bupa = await cds.connect.to('API_BUSINESS_PARTNER')

    this.on('READ', 'Customers', (req) => {
      console.log('>> delegating to remote service...')
      return S4bupa.run(req.query)
    })
```

Let's walk through this code at a high level. 

As a result of the `cds.connect.to('API_BUSINESS_PARTNER')` call, the `S4bupa` constant will contain a connection object that can be used for remote communication with the service specified (i.e. with `API_BUSINESS_PARTNER`), based on whatever information is in the corresponding `cds.requires` section of the configuration loaded at runtime.

We're currently mocking that service, and we can see the details that will be available at runtime in the `~/.cds-services.json` file that we've looked at in previous exercises. In fact, because the `cds mock API_BUSINESS_PARTNER` process is still running, that file contains, right now, information that looks like this:

```json
{
  "cds": {
    "provides": {
      "API_BUSINESS_PARTNER": {
        "kind": "odata",
        "credentials": {
          "url": "http://localhost:5005/api-business-partner"
        }
      }
    }
  }
}
```

In other words, the connection object will essentially point to `http://localhost:5005/api-business-partner`.

> The beauty of this approach is that connection information remains abstract and separate from the service implementation, which is especially important when moving across tiered landscapes and also to protect credentials and manage their lifecycle separately.

Continuing to look through the code in `srv/incidents-service.js`, this connection object is then used, when handling the `READ` event for the `Customers` entity, to relay the actual request (in `req.query`) to the remote system (via `S4bupa.run()`). The response to this remote request is then returned to the original requester (i.e. the request that invoked this `READ` event in the first place).

### Try it out

👉 Now, while leaving the `cds mock API_BUSINESS_PARTNER` still running, restart the main CAP server process:

```bash
cds watch
```

👉 Observe the log output, and you should see something new:

```text
[cds] - connect to API_BUSINESS_PARTNER > odata { url: 'http://localhost:5005/api-business-partner' }
```

This is a direct result of this part of the code you added:

```js
await cds.connect.to('API_BUSINESS_PARTNER')
```

Note that this is just an indication that the remote connection details have been marshalled and calls to the remote system can be made as and when required. No calls have actually been made yet, as you can observe from the fact that the log output from the mocked `API_BUSINESS_PARTNER` service (in the other terminal) shows no activity.

👉 Make a request to the `Customers` entity set again via <http://localhost:4004/incidents/Customers>.

Whoops!

Another error.

But a different one!

### Analyze the error

There's an XML based HTTP response payload with an error code (502) and a detailed message, the important part of which is this:

```text
Error during request to remote service: Cannot find module '@sap-cloud-sdk/http-client'
```

👉 Head over to the log output of the main CAP server process and take a look. You should see something like this (heavily reduced for brevity):

```text
>> delegating to remote service...
[remote] - Error: Error during request to remote service:
Cannot find module '@sap-cloud-sdk/http-client'
requireStack: [
  '/workspaces/cap-service-integration-codejam/incidents/node_modules/@sap/cds/libx/_runtime/remote/utils/client.js',
  '/workspaces/cap-service-integration-codejam/incidents/node_modules/@sap/cds/libx/_runtime/remote/Service.js',
  '/workspaces/cap-service-integration-codejam/incidents/node_modules/@sap/cds/lib/index.js',
  '/workspaces/cap-service-integration-codejam/incidents/node_modules/@sap/cds/bin/cds.js',
  '/usr/local/share/npm-global/lib/node_modules/@sap/cds-dk/bin/cds.js',
  '/usr/local/share/npm-global/lib/node_modules/@sap/cds-dk/bin/watch.js'
],
request: {
  method: 'GET',
  url: '/A_BusinessPartner?$select=BusinessPartner,BusinessPartnerFullName&$orderby=BusinessPartner%20asc&$top=1000',
  headers: {
    accept: 'application/json,text/plain',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
    'x-correlation-id': '3e57c08d-e7a1-41d9-92db-0d1c14fa3c0e'
  }
}
```

Let's see what we can discern from this:

* we can see the log message (`>> delegating to remote service...`) appears directly before the error
* there's a requirement for for an NPM package `@sap-cloud-sdk/http-client` (which we haven't explicitly installed)
* there's an HTTP GET request being attempted at the time of failure
* this HTTP request is to the following relative URL (URL-decoded and with whitespace added for readability):
    ```text
    /A_BusinessPartner
    ?$select=BusinessPartner,BusinessPartnerFullName
    &$orderby=BusinessPartner asc
    &$top=1000
    ```

If you were thinking that this was the direct result of the call to `S4bupa.run(req.query)`, which in turn was the direct result of the `READ` event for `Customers` being triggered, which in turn was a direct result of you making a request to `http://localhost:4004/incidents/Customers`, you'd be spot on.

CAP makes use of the SAP Cloud SDK. Specifically for remote connectivity, the `@sap-cloud-sdk/http-client` is employed, because it handles connectivity related issues such as destination lookup, connections to SAP S/4HANA On-premise and web proxies, and more. There's a link in the [Further reading](#further-reading) section below that will take you to the SAP Cloud SDK guide.

### Install the @sap-cloud-sdk/http-client package

So let's install what's needed.

👉 Stop the main CAP server process again with Ctrl-C.

👉 Now, making sure you're still in the `incidents/` directory, add the package:

```bash
npm add @sap-cloud-sdk/http-client
```

> `add` is just a synonym for `install` here.

👉 Once the package has been installed (and it will have been added to the list of `dependencies` in the project's `package.json` file), start the main CAP server up one more time, but this time, specify the value `remote` for the `DEBUG` environment variable, so that the CAP server will emit extra information on remote service activities:

```bash
DEBUG=remote cds watch
```

> Setting an environment variable like this "in-line" with a command means that it will be set for that command only. After you terminate the `cds watch` command here, the value of `DEBUG` will be whatever it was before this invocation, possibly (and probably, in the context of this exercise) nothing. See the [Further reading](#further-reading) section below for more information on the use of `DEBUG`.

👉 Re-request that `Customers` entity set at <http://localhost:4004/incidents/Customers>. You should now get the data, instead of the error, and it will look something like this:

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
[cds] - GET /api-business-partner/A_BusinessPartner?$select=BusinessPartner,BusinessPartnerFullName&$orderby=BusinessPartner asc&$top=1000
```

This is indeed the same request that was attempted before, that we saw in the error message above.

👉 And in fact, if you check the log output from the serving of the main service (the one started with `cds watch`), you should see something like this (with the detailed log line prefixed "[remote]" being emitted specifically because of `DEBUG=remote`):

```text
[cds] - GET /incidents/Customers
>> delegating to S4 service...
[remote] - GET http://localhost:5005/api-business-partner/A_BusinessPartner?$select=BusinessPartner,BusinessPartnerFullName&$orderby=BusinessPartner%20asc&$top=1000 {
  headers: {
    accept: 'application/json,text/plain',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
    'x-correlation-id': 'bb9bbbd7-816f-4a60-9631-104ba231eeff'
  },
  data: undefined
}
```

This is a sign of a successful delegation to a remote service!

## Summary

At this point: 

* you're running your external service in a mocked but real, remote service, accessed via HTTP
* you've added handler code for the appropriate event to delegate calls to that remote service as required
* you've installed the HTTP client library from the SAP Cloud SDK to make this connectivity and remote calling possible

Great work!

## Further reading

* [Providing Service Implementations](https://cap.cloud.sap/docs/get-started/in-a-nutshell#providing-service-implementations)
* [cds.connect.to(name, options?)](https://cap.cloud.sap/docs/node.js/cds-connect#cdsconnectto--name-options--service)
* [SAP Cloud SDK (JavaScript)](https://sap.github.io/cloud-sdk/docs/js/getting-started)
* [@sap-cloud-sdk/http-client NPM package](https://www.npmjs.com/package/@sap-cloud-sdk/http-client)
* [DEBUG env variable](https://cap.cloud.sap/docs/node.js/cds-log#debug-env-variable)

---

## Questions

If you finish earlier than your fellow participants, you might like to ponder these questions. There isn't always a single correct answer and there are no prizes - they're just to give you something else to think about.

1. When you "make a request to the `Customers` entity set again", what type of OData operation is it?

1. If you stop the mocked external service process (the one you started with `cds watch API_BUSINESS_PARTNER --port 5005`) and then make a call to the `Customers` entity set again, what happens?

---

[Next exercise](../09-set-up-remote-system-configuration/)
