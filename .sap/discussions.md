# Exercise 01 - Set up your workspace

_What are the advantages of using container images for development work?_

There are many, including:

* consistent: a container image can represent a reproducible environment for development, testing or other related purposes
* shareable: everyone can have the same environment regardless of the actual OS running on their local machine
* focused: tools that are only relevant for a given development stack or task can be installed as part of the image and not pollute the host OS
* portable: anywhere that has a container engine can be used as a host for development and the experience is the same
* onboarding: a repo containing development artifacts can also contain an image description file (such as a `Dockerfile`) that can enable a much quicker onboarding for new developers

See [Reproducible Development with Devcontainers](https://www.infoq.com/articles/devcontainers/).

_What is the difference between the `@sap/cds` and `@sap/cds-dk` packages?_

The `dk` stands for Development Kit and refers to the extra tools made available for design, development and testing processes. So the former is the runtime, and the latter is the "SDK" (software development kit).

# Exercise 02 - Explore the basic service

_While there are two imported namespaces shown when examining the `db/schema.cds` contents (`global` and `sap.common`), there are three shown when examining the `srv/incidents-service.cds` contents. What is the third, and where does that come from?_

There is a third because basically we have moved up a layer in the CAP service, from the persistence layer to the service layer. So while at the persistence layer (in `db/schema.cds`) the namespace was `acme.incmgt` and, via the `using` statement we got `sap.common` and `global` by default as imported namespaces ... at this service layer, the file-local name (in `srv/incidents-service.cds`) is `IncidentsService` (the name of the service declared in the file) and we then have the three namespaces from the persistence layer as imported namespaces, brought in via the `using { acme.incmgt } from '../db/schema'` statement.

![the namespaces at the service layer](assets/incidents-service-namespaces.png)

_In looking at the graphical display of the `srv/incidents-service.cds` contents, one of the entities (from the `db/schema.cds` layer) wasn't shown. Which one, and why?_

In `db/schema.cds` there's another entity `TeamCalendar`. That is the one that is not shown. It's simply because it is not exposed (like the others are, via entity projections), in the `IncidentsService` service in `srv/incidents-service.cds`.

_There's a lot to unpack from the initial output of `cds watch`. What does the output tell you?_

There is a lot to see. Briefly (as some of this will be pointed out in the next exercise):

* the `cds watch` command is actually something a little more complicated underneath (see the next question)
* we can see that `cds watch` is part of the set of development tools as it has a "live reload" facility built in for comfortable development with rapid turnaround of feedback and results
* the CAP server has identified the model that it should serve, and shows us where it's getting the model definitions from
* also as part of the development tools set we see the use of the user-local-and-private `~/.cds-services.json` file
* as part of the convention over configuration approach the server starts up with an SQLite powered in-memory storage mechanism
* the storage is for persisting data for the entities, in the form of tables (and views), seed data for which can be supplied in (and is being loaded from) CSV files, again, because of what they've been named (`<namespace>-<Entity name>`) and where they've been stored (`db/data/`)
* the CAP server will serve the service(s) defined, and also make some sensible choices on service path names (for example here, the `IncidentsService` service is served at `/incidents` (lowercase, without an explicit "service" suffix)
* the default port for CAP services is 4004; and while the URL shown is `http://localhost:4004`, suggesting that the socket is only available on the loopback device (127.0.0.1), it is in fact listening on `INADDR_ANY` (i.e. 0.0.0.0), as we can see:
    ```console
    ; netstat -atn | grep 4004
    tcp6       0      0 :::4004                 :::*                    LISTEN
    ```

_`cds watch` is actually just a shortcut for another `cds` command. What is it?_

We can see the answer to this by simply examining the CAP server output (see the previous question) which shows us `cds serve all --with-mocks --in-memory?`, or by looking at the output from `cds watch --help`, which tells us the same thing:

```text

SYNOPSIS

  cds watch [<project>]

  Tells cds to watch for relevant things to come or change in the specified
  project or the current work directory. Compiles and (re-)runs the server
  on every change detected.

  Actually, cds watch is just a convenient shortcut for:
  cds serve all --with-mocks --in-memory?
```

_In the "Welcome to @sap/cds Server" landing page at <http://localhost:4004>, where do the details `Serving @acme/incidents-mgmt 1.0.0` come from?_

The values here are from within the [package.json](../incidents/package.json) file, specifically the values of the `name` and `version` properties.

# Exercise 03 - Import an OData service definition

_Did you know that the SAP Business Application Studio Dev Spaces offer a [Service Center](https://help.sap.com/docs/SAP%20Business%20Application%20Studio/9d1db9835307451daa8c930fbd9ab264/1e8ec75c9c784b51a91c7370f269ff98.html) which lets you browse content from various sources, including the SAP Business Accelerator Hub?_

(Note that, at least at the time of writing, the Service Center does not yet reflect "SAP Business Accelerator Hub" as the new name for "SAP API Business Hub").

_What does "A2X" stand for and represent?_

The SAP Business Accelerator Hub [contains many APIs that are marked "A2X"](https://www.google.com/search?q=site%3Aapi.sap.com+%22A2X%22), and it's an important identifier. While "A2A" stands for "Application to Application", suggesting backend(-only) systems that talk to each other, "A2X" stands for "Application to X users" and is normally used to classify synchronous APIs that are used (amongst other purposes) for consumption in frontend (UI) applications. A2X APIs are mostly RESTful in nature (such as OData services) and also often contain annotations (metadata) that can be used by the presentation level to influence the user interface that makes use of data from such an API. See [APIs on SAP API Business Hub](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/8308e6d301d54584a33cd04a9861bc52/1e60f14bdc224c2c975c8fa8bcfd7f3f.html?locale=en-US) (sic) for more detail.

_If you [tried out](https://api.sap.com/api/API_BUSINESS_PARTNER/tryout) the Business Partner (A2X) API in the browser, did you notice some of the parameters available for GET requests to the main resources (such as `/A_AddressEmailAddress` or `/A_BusinessPartner`) included ones beginning with `$`? What were they, did you recognize them?_

This question is referring to parameters such as `$top`, `$skip`, `$filter`, and so on. They are [OData system query options](https://docs.oasis-open.org/odata/odata/v4.01/odata-v4.01-part2-url-conventions.html#_Toc31360955), and are recognizable by their `$` prefix.

_When looking at the "Business Partner" endpoints, did you notice the "/A\_" prefix on each of the endpoints? What do you think that signifies?_

This prefix comes from the naming conventions used in the SAP S/4HANA Virtual Data Model (VDM). Different views of the same underlying persistence-level entity are named with prefixes that describe what type of views they are. There are Basic, Consumption and Composite views, and also Remote API views, which is what the "/A\_" prefixed names are from. In the [Further reading](../exercises/03-import-odata-api/README.md#further-reading) section of this exercise, there's a link to an article on the topic.

# Exercise 04 - Understand service mocking

_In the [Understand what is happening with mocking](/exercises/04-understand-service-mocking/README.md#understand-what-is-happening-with-mocking) section, you got the following output; what is this, and what does it tell us?_

```json
{
  "@odata.context": "$metadata#A_BusinessPartner",
  "value": []
}
```

In that section we actually made two requests:

1. <http://localhost:4004/api-business-partner/A_BusinessPartner>
1. <http://localhost:4004/incidents/Customers>

So first, this tells us that this is a response for the first request. It tells us that the data context is the entity set "A_BusinessPartner" (see the list of entity sets and their URLs in the service document at <http://localhost:4004/api-business-partner>). Specifically it refers to the `A_BusinessPartner` entity set and type in the metadata document. So we know it's a list of business partners. But the list - the `[ ... ]` array which is the value of the `value` property, is empty, i.e. right now no business partner records are available.

# Exercise 05 - Add test data for the mocked external service

_Is CSV data supplied for the entire external service, or just a single entity within that? What about at the property level within the entity?_

It's just for the single entity "A_BusinessPartner". We can see that from the fact that there's just a single CSV file, and we know that the convention is that there's generally one file per entity. Moreover, there are only two fields in the CSV data, whereas there are many, many properties in the actual definition of the `A_BusinessPartner` type. How many? Hmm, let's see:

```console
; jq '
.definitions
| with_entries(select(.key | endswith("A_BusinessPartner")))
| to_entries[0].value.elements
| length
' srv/external/API_BUSINESS_PARTNER.csn
84
```

_Normally, one might expect data files to be provided at the persistence layer, i.e. somewhere within the `db/` directory. But the data we provided here was not in there. Where was it, and why? Would it work if you put it into `db/data/`?_

The philosophy and mental model of having this external service, and everything related to it, in `srv/external/` actually is at two levels:

* the external service is a _service_ and therefore doesn't fit as well being placed at the same level as the persistence layer definitions
* we want to think about it and treat it as a separate, self-contained resource, so having test data in that same self-contained place makes total sense

If you moved `API_BUSINESS_PARTNER-A_BusinessPartner.csv` out of `srv/external/data/` and put it into `db/data/` and restarted the CAP server, you'd see:

```log
> init from db/data/API_BUSINESS_PARTNER-A_BusinessPartner.csv
```

instead of

```log
> init from srv/external/data/API_BUSINESS_PARTNER-A_BusinessPartner.csv
```

and it would still work, data would still be served at <http://localhost:4004/api-business-partner/A_BusinessPartner?$select=BusinessPartnerFullName>.

# Exercise 06 - Mock external service in a separate process

_Could you choose any port with the `--port` option? What about, say, port 42, or 1023? What happens, and why?_

Ports below 1024 are privileged, i.e. administrative privileges are required to bind to and listen on ports below that number. This is because standard services (such as HTTP, HTTPS, FTP, POP3, SMTP, etc) all listen on low numbered ports, so preventing non-root users from running a service on a low numbered port is a security feature (to prevent service spoofing). See [Priviliged Ports](https://www.w3.org/Daemon/User/Installation/PrivilegedPorts.html) (sic) for more detail. What actually happens in the current CAP server implementation is that no error will be issued if you specify a port below 1024 (e.g. with `--port 80`) but the service will be started on a random (high numbered) port implicitly.

# Exercise 07 - Add CDS definitions to integrate services

_Does the diagram above make sense? How do you visualize the different layers and components of your CAP services? Do you have a different approach?_

This is a question to provide the context for a general discussion on layering and organization of local & remote resources, and mashups.

_After [creating a projection on the external service](../exercises/07-add-cds-definitions/README.md#create-a-projection-on-the-external-service) where you added content in `srv/external/index.cds`, we noted that there was no difference in what was served, after the CAP server restart - the "Loaded model from N file(s)" message didn't show this new file. Do you know why that was?_

This is down to the default locations, known as "roots", from where the CAP server will automatically fetch and load CDS definitions. These are `db/index.cds` (or `db/*.cds`), `srv/index.cds` (or `srv/*.cds`), `app/index.cds` (or `app/*.cds`), plus `schema.cds` and `services.cds`. You can check what these locations are, they're available in the cds env:

```console
cds env get roots
[ "db/", "srv/", "app/", "schema", "services" ]
```

So while `index.cds` is indeed a "default" CDS file name (a bit like the `index.html` in the classic [Apache's HTTP Server](https://httpd.apache.org/docs/trunk/getting-started.html#page-header) software), it's not in any of the roots, so won't be loaded by default.

See [Customizing Layouts](http://web.archive.org/web/20221207175033/https://cap.cloud.sap/docs/get-started/projects#customizing-layouts) in the older Capire docu for more detail.

# Exercise 08 - Introduce the SAP Cloud SDK

_When you "make a request to the `Customers` entity set again", what type of OData operation is it?_

It's an OData query operation. With a query operation one requests zero, one or more entities in an entity set that is to be the response. The entity set (that used to be a `<feed>` top-level element in OData v2 when the default representation was `atom/xml` - see <https://services.odata.org/V2/OData/OData.svc/Products> for an example) is what distinguishes this from the response to an OData read operation, which is a request for a single entity (and which used to be an `<entry>` element, see <https://services.odata.org/V2/OData/OData.svc/Products(1)> for an example of that).

The representations (we'll look at them in their JSON representations here as CAP will serve OData v4 by default) differ.

Here's a typical entity set response (i.e. to an OData query operation, specifically <http://localhost:4004/incidents/Customers>) - note the reference to `$metadata#Customers` which tells us (implicitly) it's an entity set:


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

Here's a typical entity response (i.e. to an OData read operation, specifically <http://localhost:4004/incidents/Customers/Z100001>) - note the reference to `$metadata#Customers/$entity` which is more explicit about the context being an entity; note also that the properties (`ID` and `name`) are provided directly, not within any array "container" property:

```json
{
  "@odata.context": "$metadata#Customers/$entity",
  "ID": "Z100001",
  "name": "Harry Potter"
}
```

_If you stop the mocked external service process (the one you started with `cds mock API_BUSINESS_PARTNER --port 5005`) and then make a call to the `Customers` entity set again, what happens?_

We get yet another error, from which we can also learn something. It's not really unexpected, and tells us exactly what's happened:

```xml
<error xmlns="http://docs.oasis-open.org/odata/ns/metadata">
  <code>502</code>
  <message>Error during request to remote service: connect ECONNREFUSED 127.0.0.1:5005</message>
</error>
```

# Exercise 09 - Set up the real remote system configuration

_In the second instance of the `curl` invocation, the `--compressed` option was used. There was a response header that tells us what the compression technique was - what was that response header and what was the encoding?_

The representation in response to a request for the resource at <https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner?$top=50&$inlinecount=allpages> is transferred in a compressed form. In other words, the output will be binary data and unreadable. To be fair, along with the "Content-Type" header, the web server sending the response also includes a "Content-Encoding" header in the HTTP response indicating the compression technique used ([gzip](https://www.gnu.org/software/gzip/)):

```log
Content-Type: application/atom+xml;type=feed; charset=utf-8
Content-Encoding: gzip
```

Using the `--compressed` explicitly in the invocation tells curl to request a compressed response, and to automatically decompress the content. This has two effects; first, curl sends this header in the HTTP request:

```log
Accept-Encoding: deflate, gzip, br
```

And then it automatically will decompress whatever is returned, according to the compression technique declared in the "Content-Encoding" header of the response.

_When [requesting business partner data from the sandbox](/exercises/09-set-up-remote-system-configuration/README.md#retry-the-request-using-the-api-key) we got an XML response. If we wanted a JSON response (to match what we got when trying it out in the sandbox on the SAP Business Accelerator Hub website), how might we request that? There are two ways - what are they?_

One is to add the [$format](https://docs.oasis-open.org/odata/odata/v4.01/odata-v4.01-part2-url-conventions.html#_Toc31361046) system query option to the query string in the request's URL, like this:

```shell
read -rp "API key? " APIKEY \
&& curl \
  --verbose \
  --compressed \
  --location \
  --header "APIKey: $APIKEY" \
  --url 'https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner?$format=json&$top=50&$inlinecount=allpages'
```

The other is to use [content negotiation](https://en.wikipedia.org/wiki/Content_negotiation) by specifying an "Accept" header in the HTTP request what the desired content type should be, like this:

```shell
read -rp "API key? " APIKEY \
&& curl \
  --verbose \
  --compressed \
  --location \
  --header "APIKey: $APIKEY" \
  --header "Accept: application/json" \
  --url 'https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner?$top=50&$inlinecount=allpages'
```

> The correct MIME type for JSON is 'application/json', see [Common MIME Types](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types).

# Exercise 10 - Run the service with real remote delegation

_When we [started the CAP server](/exercises/10-run-with-real-remote-delegation/README.md#start-the-cap-server), why did we observe a difference between the remote system types "odata" and "odata-v2"?_

This is because the real service, served by the SAP API Business Accelerator Hub's sandbox system, is an OData V2 service:

![the API is an OData V2 service](assets/api-is-odata-v2.png)

Remember the stanza added to `package.json` for this external service actually has "odata-v2" explicitly, in the `kind` property:

```json
{
  "API_BUSINESS_PARTNER": {
    "kind": "odata-v2",
    "model": "srv/external/API_BUSINESS_PARTNER"
  }
}
```

But the mocked version of the service, provided by the CAP server (the separate process started with `cds mock API_BUSINESS_PARTNER`) is not V2, but V4 (represented here simply by "odata" rather than "odata-v2"). V4 is CAP's default for OData (and quite appropriately too, given that [OData v4 has been in existence for a decade already](https://github.com/qmacro/odata-specs/blob/master/overview.md)).

_If you were to have omitted the `--profile sandbox` option when running `cds watch`, what would have happened?_

We'd be back to the in-process mocking of the `API_BUSINESS_PARTNER` service.

Why?

Because without the `--profile sandbox`, the only information relating to this service is the `kind` and `model`, and not any `credentials` properties. In other words, no external bindings. And if there are no external bindings, and we run `cds watch`, which, as we have learned, is just syntactic sugar for `cds serve  all --with-mocks --in-memory?`, then any service without external bindings are automatically mocked for us. This is what `--with-mocks` does.

Note the difference between the output for `cds env get` with and without the `--profile sandbox` option:

```shell
cds env get requires.API_BUSINESS_PARTNER --profile sandbox
```

Returns:

```json
{
  "impl": "@sap/cds/libx/_runtime/remote/Service.js",
  "external": true,
  "kind": "odata-v2",
  "model": "srv/external/API_BUSINESS_PARTNER",
  "credentials": {
    "url": "https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER",
    "headers": {
      "APIKey": "<YOUR-API-KEY>"
    }
  }
}
```

Whereas:

```shell
cds env get requires.API_BUSINESS_PARTNER
```

returns just:

```json
{
  "impl": "@sap/cds/libx/_runtime/remote/Service.js",
  "external": true,
  "kind": "odata-v2",
  "model": "srv/external/API_BUSINESS_PARTNER"
}
```

_Why was there a `$select=BusinessPartner,BusinessPartnerFullName` in the query made to the remote system?_

Because these are the only two properties required, according to the projection made in [../exercises/07-add-cds-definitions/README.md#07-add-cds-definitions#create-a-projection-on-the-external-service):

```cds
entity Customers as projection on API_BUSINESS_PARTNER.A_BusinessPartner {
  key BusinessPartner as ID,
  BusinessPartnerFullName as name
}
```

It makes sense to reduce to a minimum the amount of data being requested and transferred.

# Exercise 11 - Associate local and remote entities

_The name of the new property that appeared in each `Incidents` entity was `customer_ID`. Where does that name (especially the `_ID` part) come from? This name appears as the name of the new `Property` element in the `Incidents` entity type definition in the metadata too, and there, there's a value of `10` for the `MaxLength` attribute. Where is that coming from?_

# Exercise 12 - Extend SAP Fiori elements UI with annotations

_When you added the annotation to include the "Customer" field in the "General Information" field group, the value of the `Data` array looked like this (compressed for brevity): `Data: [ { Value: customer_ID, Label: 'Customer'}, ... ]`. What happens if you switch around the ellipsis (`...`) to come before the object describing the "Customer" field in the array, instead of after it?_

