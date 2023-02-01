# Exercise 06 - Mock external service in a separate process

At the end of this exercise, you'll have tried out the alternative to in-process mocking, having the mocked service in a separate process.

## Consider the current mocking setup

In [exercise 04](../04-understand-service-mocking/) we ended up with our local `/incidents` service, plus a mocked instance of our external service at `/api-business-partner`, both being served from within the same process, i.e. from the same single CAP server, initiated with `cds watch`. 

The salient line in the log output is this:

```text
[cds] - mocking API_BUSINESS_PARTNER { path: '/api-business-partner' }
```

Requests to resources starting with the path `/api-business-partner` are resolved by the CAP server that is also resolving requests to the `/incidents` service.

The advantage of having external services mocked like is clear - it's the simplest and fastest way to get going when developing CAP services that consume other remote services. 

But the disadvantage is that this is not representative of how the real cross-service communication will happen. The mocked service doesn't behave as a real external service, and the communication happens in-process, rather than over HTTP, for example using the OData protocol.

## Run the mocked API_BUSINESS_PARTNER service in a separate process

It's possible to mock external services in a separate process, and in this section you're going to try that out.

👉 First, stop any CAP server, using Ctrl-C to exit any `cds run` or `cds watch` invocations that might still be active.

👉 After you're sure there's nothing running, start a monitor to display whatever is in the `~/.cds-services.json` file we learned about in [exercise 04](../04-understand-service-mocking/):

```bash
watch -c jq -C ~/.cds-services.json
```

> The `-c` option to `watch` tells it to interpret ANSI color and style sequences, which we explicitly tell `jq` to emit with the `-C` option. Normally, `jq` won't bother to emit them if it thinks, correctly here, that its output is not directly in the context of a terminal (it's in the context of the `watch` process, here), but we can force its hand.

It should show that there are currently no services provided, something like this:

```json
{
  "cds": {
    "provides": {}
  }
}
```

👉 Now, open up a second terminal, and in there, start the mocking of the external service like this:

```bash
cds mock API_BUSINESS_PARTNER
```

> What's happening here? Well, as we're beginning to learn, commands that look simple are just syntactic sugar for more explicit and specific invocations. This is shorthand for --`cds serve --mocked API_BUSINESS_PARTNER`.

Two things happen that are of interest to us here. 

First, we see some log output that looks vaguely familiar:

```text

[cds] - mocking API_BUSINESS_PARTNER { path: '/api-business-partner' }

[cds] - server listening on { url: 'http://localhost:45149' }
```

Note however that it's not the default port 4004 that's being used, it's a random one (45149). Think of this distinction as the distinction between the "main" service at the `/incidents` endpoint that we would want to have served on 4004, and this temporary external service that is just running on a random port as it's "secondary", and would have a different hostname and port (representing the SAP S/4HANA Cloud system) when we move into production anyway. 

You can use the `--port` option to specify a port explicitly, if you want, e.g. `cds mock API_BUSINESS_PARTNER --port 3003`. In fact, we're going to use that now, mostly to make this CodeJam content (and specifically the URLs) consistent and usable for everyone. 

👉 Stop that mocked service with Ctrl-C, and then restart it, specifying the explicit port of 5005:

```bash
cds mock API_BUSINESS_PARTNER --port 5005
```

The second thing to notice is that the mocked service appears in the `~/.cds-services.json` file in the `provides` section, with the appropriate URL in the `credentials` section, like this (now with the newly specified port of 5005):

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

## Start up the main service

Now we have a mocked version of the external service running in an independent process, we can start up the main service. 

👉 Do that now. Open up a third (yes, third) terminal, and use `cds watch`:

```bash
cds watch
```

The output should look familiar:

```text
cds serve all --with-mocks --in-memory? 
watching: cds,csn,csv,ts,mjs,cjs,js,json,properties,edmx,xml,env,css,gif,html,jpg,png,svg... 
live reload enabled for browsers 

        ___________________________

 
[cds] - loaded model from 5 file(s):

  db/schema.cds
  srv/incidents-service.cds
  app/fiori.cds
  srv/external/API_BUSINESS_PARTNER.csn
  ../../../usr/local/share/npm-global/lib/node_modules/@sap/cds-dk/node_modules/@sap/cds/common.cds

[cds] - connect using bindings from: { registry: '~/.cds-services.json' }
[cds] - connect to db > sqlite { url: ':memory:' }
 > init from db/data/acme.incmgt-Appointments.csv
 > init from db/data/acme.incmgt-Incidents.conversation.csv
 > init from db/data/acme.incmgt-Incidents.csv
 > init from db/data/acme.incmgt-Incidents_status.csv
 > init from db/data/acme.incmgt-Incidents_urgency.csv
 > init from db/data/acme.incmgt-Incidents_urgency.texts.csv
 > init from db/data/acme.incmgt-ServiceWorkers.csv
 > init from db/data/acme.incmgt-TeamCalendar.csv
/> successfully deployed to sqlite in-memory db

[cds] - serving IncidentsService { path: '/incidents', impl: 'srv/incidents-service.js' }

[cds] - server listening on { url: 'http://localhost:4004' }
[cds] - launched at 1/30/2023, 3:47:13 PM, version: 6.4.1, in: 1.150s
[cds] - [ terminate with ^C ]
```

Note however that in contrast to when we originally [introduced mocking in exercise 04](../04-understand-service-mocking/README.md#introduce-mocking), the output of this `cds mock` invocation does not include this line:

```text
[cds] - mocking API_BUSINESS_PARTNER { path: '/api-business-partner' }
```

That's because `cds watch` looks for running services listed as provided in the `~/.cds-services.json` file and connects to them. It found the entry for `API_BUSINESS_PARTNER` in there, meaning that there was no need to mock it itself.

👉 Check again the contents of the `~/.cds-services.json` file, where you should now see an entry for the main service too, on the default port:

```json
{
  "cds": {
    "provides": {
      "API_BUSINESS_PARTNER": {
        "kind": "odata",
        "credentials": {
          "url": "http://localhost:5005/api-business-partner"
        }
      },
      "IncidentsService": {
        "kind": "odata",
        "credentials": {
          "url": "http://localhost:4004/incidents"
        }
      }
    }
  }
}
```

## Summary

At this point you have your main service up and running at <http://localhost:4004> and the external `API_BUSINESS_PARTNER` service mocked and running at <http://localhost:5005>. If you visit the `/A_BusinessPartner` entity set in that mocked service, at <http://localhost:5005/api-business-partner/A_BusinessPartner?$count=true>, you'll see that the data you provided via CSV is still being served (and you can see the details of those requests in the log output in the second terminal window).

For simplicity's sake for the rest of the CodeJam, let's switch back to an in-process mocking setup, so you don't have to run multiple terminal windows.

👉 Stop both `cds watch` processes, and also the `watch` process if it's still running, with Ctrl-C. You can now close all but one terminal window in your workspace. In the remaining terminal window, run `cds watch` again, which should start a single process, with the CAP server listening on port 4004, mocking the external service and serving your main service too.

## Further reading

* [Mock Remote Service as OData Service (Node.js)](https://cap.cloud.sap/docs/guides/using-services#mock-remote-service-as-odata-service-nodejs)
* [watch (command)](https://en.wikipedia.org/wiki/Watch_(command))
* [Invoking jq](https://stedolan.github.io/jq/manual/#Invokingjq)

---

## Questions

If you finish earlier than your fellow participants, you might like to ponder these questions. There isn't always a single correct answer and there are no prizes - they're just to give you something else to think about.

---

[Next exercise](../07-add-cds-definitions/)
