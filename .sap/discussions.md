# Exercise 01 - Set up your workspace


What are the advantages of using container images for development work?

What is the difference between the `@sap/cds` and `@sap/cds-dk` packages?


# Exercise 02 - Explore the basic service


While there are two imported namespaces shown when examining the `db/schema.cds` contents (`global` and `sap.common`), there are three shown when examining the `srv/incidents-service.cds` contents. What is the third, and where does that come from?

In looking at the graphical display of the `srv/incidents-service.cds` contents, one of the entities (from the `db/schema.cds` layer) wasn't shown. Which one, and why?

There's a lot to unpack from the initial output of `cds watch`. What does the output tell you?

`cds watch` is actually just a shortcut for another `cds` command. What is it?

In the "Welcome to @sap/cds Server" landing page at <http://localhost:4004>, where do the details `Serving @acme/incidents-mgmt 1.0.0` come from?


# Exercise 03 - Import an OData service definition


Did you know that the SAP Business Application Studio Dev Spaces offer a [Service Center](https://help.sap.com/docs/SAP%20Business%20Application%20Studio/9d1db9835307451daa8c930fbd9ab264/1e8ec75c9c784b51a91c7370f269ff98.html) which lets you browse content from various sources, including the SAP Business Accelerator Hub? 




What does "A2X" stand for and represent?

If you [tried out](https://api.sap.com/api/API_BUSINESS_PARTNER/tryout) the Business Partner (A2X) API in the browser, did you notice some of the parameters available for GET requests to the main resources (such as `/A_AddressEmailAddress` or `/A_BusinessPartner`) included ones beginning with `$`? What were they, did you recognize them?

When looking at the "Business Partner" endpoints, did you notice the `/A_` prefix on each of the endpoints? What do you think that signifies?


# Exercise 04 - Understand service mocking


In the [Understand what is happening with mocking](#understand-what-is-happening-with-mocking) section, you got the following output; what is this, and what does it tell us?


# Exercise 05 - Add test data for the mocked external service


Is CSV data supplied for the entire external service, or just a single entity within that? What about at the property level within the entity?

Normally, one might expect data files to be provided at the persistence layer, i.e. somewhere within the `db/` directory. But the data we provided here was not in there. Where was it, and why? Would it work if you put it into `db/data/`?


# Exercise 06 - Mock external service in a separate process


Could you choose any port with the `--port` option? What about, say, port 42, or 1023? What happens, and why? 


# Exercise 07 - Add CDS definitions to integrate services


Does the diagram above make sense? How do you visualize the different layers and components of your CAP services? Do you have a different approach?

_After [creating a projection on the external service](../exercises/07-add-cds-definitions/README.md#create-a-projection-on-the-external-service) where you added content in `srv/external/index.cds`, we noted that there was no difference in what was served, after the CAP server restart - the "Loaded model from N file(s)" message didn't show this new file. Do you know why that was?_

This is down to the default locations, known as "roots", from where the CAP server will automatically fetch and load CDS definitions. These are `db/index.cds` (or `db/*.cds`), `srv/index.cds` (or `srv/*.cds`), `app/index.cds` (or `app/*.cds`), plus `schema.cds` and `services.cds`. You can check what these locations are, they're available in the cds env:

```console
cds env get roots
[ "db/", "srv/", "app/", "schema", "services" ]
```

So while `index.cds` is indeed a "default" CDS file name (a bit like the `index.html` in the classic [Apache's HTTP Server](https://httpd.apache.org/docs/trunk/getting-started.html#page-header) software), it's not in any of the roots, so won't be loaded by default. 

See [Customizing Layouts](http://web.archive.org/web/20221207175033/https://cap.cloud.sap/docs/get-started/projects#customizing-layouts) in the older Capire docu for more detail.

# Exercise 08 - Introduce the SAP Cloud SDK


When you "make a request to the `Customers` entity set again", what type of OData operation is it?

If you stop the mocked external service process (the one you started with `cds watch API_BUSINESS_PARTNER --port 5005`) and then make a call to the `Customers` entity set again, what happens?


# Exercise 09 - Set up the real remote system configuration


In the `curl` invocation, the `--compressed` option was used. There was a response header that tells us what the compression technique was - what was that response header and what was the encoding?

When [requesting business partner data from the sandbox](#retry-the-request-using-the-api-key) we got an XML response. If we wanted a JSON response (to match what we got when trying it out in the sandbox on the SAP Business Accelerator Hub website), how might we request that? There are two ways - what are they?


# Exercise 10 - Run the service with real remote delegation


When we [started the CAP server](#start-the-cap-server), why did we observe a difference between the remote system types "odata" and "odata-v2"?

If you were to have omitted the `--profile sandbox` option when running `cds watch`, what would have happened?


# Exercise 11 - Associate local and remote entities


The name of the new property that appeared in each `Incidents` entity was `customer_ID`. Where does that name (especially the `_ID` part) come from? This name appears as the name of the new `Property` element in the `Incidents` entity type definition in the metadata too, and there, there's a value of `10` for the `MaxLength` attribute. Where is that coming from?


# Exercise 12 - Extend SAP Fiori elements UI with annotations


When you added the annotation to include the "Customer" field in the "General Information" field group, the value of the `Data` array looked like this (compressed for brevity): `Data: [ { Value: customer_ID, Label: 'Customer'}, ... ]`. What happens if you switch around the ellipsis (`...`) to come before the object describing the "Customer" field in the array, instead of after it? 

