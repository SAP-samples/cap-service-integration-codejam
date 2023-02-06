# Exercise 07 - Add CDS definitions to integrate services

In an earlier exercise, we [took a naïve approach to incorporating the external service](../04-understand-service-mocking/README.md#take-a-naïve-approach-to-incorporating-the-external-service). This worked, but was a little blunt and imprecise, like joining two things together by stacking them on top of each other and hitting them with a sledgehammer. 

At the end of this exercise, you'll have added CDS definitions to both the imported external service, and to your main service, to integrate them in a cleaner and more precise way, retaining the identities of both services, in a way that makes a lot more sense when considering the availability and integration of external services more generally.

## Create a projection on the external service

The external service lives, for want of a better word, in the `srv/external/` directory. That's where it belongs, and where it can remain largely independent of your main service. It's here that for our first step towards cleaner integration, we can add some CDS definitions to "adapt" the service for our own needs. Doing it here also promotes the idea that such a model could come from a third party.

Within this `external/srv/` location, you're going to create a projection on the external service.

👉 Create a new file `index.cds` in the `srv/external/` directory, and add the following content:

```cds
using { API_BUSINESS_PARTNER } from './API_BUSINESS_PARTNER';

namespace s4.simple;

entity Customers as projection on API_BUSINESS_PARTNER.A_BusinessPartner {
  key BusinessPartner as ID,
  BusinessPartnerFullName as name
}
```

Here you've defined a new entity `Customers` as a projection on the more generic `A_BusinessPartner` from the external service, and have exposed just two properties from it. 

👉 Ensure your CAP server is still running in mock mode, on port 4004 (i.e. make sure you have `cds watch` going).

When you've saved this new `srv/external/index.cds` file, notice that when the CAP server has restarted, there is no discernible difference in what is being served; the two service endpoints at <http://localhost:4004> are still the same, and there's not yet any sign of a `Customers` entity.

## Expose the new Customers entity in your main service

Now that you have a clean and more meaningful (focused) interface to the `API_BUSINESS_PARTNER` external service, in the form of `s4.simple.Customers` with its two properties `ID` and `name` (pointing to `BusinessPartner` and `BusinessPartnerFullName` respectively), it's time to integrate that entity into your own main service.

👉 In the `srv/` directory (not in `srv/external/`) create a new file `mashup.cds` with the following contents:

```cds
using { IncidentsService } from './incidents-service';
using { s4 } from './external';

extend service IncidentsService with {
  entity Customers as projection on s4.simple.Customers;
}
```

This is what these definitions are doing:

* bringing in a reference to the `IncidentsService` from the `srv/incidents-service.cds` file, which has this content:
    ```cds
    using { acme.incmgt } from '../db/schema';

    service IncidentsService {
        entity Incidents      as projection on incmgt.Incidents;
        entity Appointments   as projection on incmgt.Appointments;
        entity ServiceWorkers as projection on incmgt.ServiceWorkers;
    }
    ```

* bringing in a reference to the top level part of the `s4.simple` namespace in the `index.cds` file we just added earlier; this namespace is where the `Customers` entity in that file belongs

* adding the `Customers` projection on to the `IncidentsService` service which already has three existing projections (`Incidents`, `Appointments` and `ServiceWorkers`)

> Did you spot the shorthand references in the second `using` statement? The first one was the import of `s4` being the entire top-level namespace which therefore includes `s4.simple`; the second one was to `./external` - the `index.cds` is defaulted.

### Consider the units of definition and their relationships

It's worth pausing here to make sure we can visualize what's happening, and where.

```text
                  +--    +------------------------------+
                  |      |                              |
                  |      |     API_BUSINESS_PARTNER     |  API_BUSINESS_PARTNER.csn
                  |      |                              |
                  |      +------------------------------+
                  |                     |
external service  |                     |
                  |                     v
                  |      +------------------------------+
                  |      |                              |
                  |      |     s4.simple.Customers      |  index.cds
                  |      |                              |
                  +--    +------------------------------+
                                        |
                                        |
                                        v
                  +--    +------------------------------+
                  |      |                              |
                  |      |        <integration>         |  mashup.cds
                  |      |                              |
                  |      +------------------------------+
                  |                     |
 service layer    |                     |
                  |                     v
                  |      +------------------------------+
                  |      |                              |
                  |      |       IncidentsService       |  incidents-service.cds
                  |      |                              |
                  +--    +------------------------------+
                                        ^
                                        |
                                        |
                  +--    +------------------------------+
                  |      |                              |
   db layer       |      | Incidents, Appointments, etc |  schema.cds
                  |      |                              |
                  +--    +------------------------------+
```

### Check the effect of the mashup definitions

What has this `extend service` definition done? Let's have a look.

👉 Head over to the service endpoints at <http://localhost:4004>, where you'll still find the service endpoint for the mocked external service, at `/api-business-partner`, and the service endpoint for your main service, at `/incidents`. 

👉 Note that the data is still being served for the `A_BusinessPartner` entity at <http://localhost:4004/api-business-partner/A_BusinessPartner> (remember, we have three test records with `BusinessPartner` keys `Z100001`, `Z100002` and `Z100003`). 

👉 In addition, note that the data is also being served for an entity in the `/incidents` service endpoint that has now started appearing since you added this bit:

```cds
extend service IncidentsService with {
  entity Customers as projection on s4.simple.Customers;
}
```

👉 That entity is `Customers` and is at <http://localhost:4004/incidents/Customers>. Access the entity now (essentially you're making an OData query on this new `Customers` entity set) and examine what is returned; it should look something like this:

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

This is the same source of data at the (mocked) persistence level, but because it's via the [projection you created earlier in this exercise](#create-a-projection-on-the-external-service), only the two properties that are defined in that projection are exposed. Neat!

## Summary

At this point you've now a cleaner integration between the external service and your own main service.

---

## Questions

If you finish earlier than your fellow participants, you might like to ponder these questions. There isn't always a single correct answer and there are no prizes - they're just to give you something else to think about.

1. Does the diagram above make sense? How do you visualize the different layers and components of your CAP services? Do you have a different approach?

---

[Next exercise](../08-introduce-sap-cloud-sdk/)
