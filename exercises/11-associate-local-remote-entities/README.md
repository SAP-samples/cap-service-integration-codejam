# Exercise 11 - Associate local and remote entities

At the end of this exercise, your main "incidents" service will be related to the external service through an association, and you'll also have added some annotations for the Fiori elements preview apps that CAP automatically make available.

## Examine what we have so far

All we have so far in terms of any relationship between the main service and the external service is the simple projection onto the `Customers` entity defined in the `index.cds` file (the "front door") in the section of the service layer that represents the external service, i.e. in `srv/external/`. 

That might be a little tough to visualize, so let's spend some time looking at how all the parts come together, and how the flexibility and beauty of certain CDS language elements allow us to maintain clean, abstract and layered solutions, with components that we author, but also with components that we can import and extend.

👉 Take a couple of moments to stare at this extended version of the diagram that we looked at in exercise 07 where we [considered the units of definition and their relationships](../07-add-cds-definitions/README.md#consider-the-units-of-definition-and-their-relationships). The projection mentioned above is marked with the arrow with the legend "PROJECTION":

```text
         +--    +-[ API_BUSINESS_PARTNER.csn : API_BUSINESS_PARTNER ]-------------------------+
         |      |                                                                             |
         |      |  Definitions from remote service:                                           |
         |      |      A_BusinessPartner,                        <--+                         |
         |      |      ...                                          |                         |
         |      |                                                   |                         |
         |      +---------------------------------------------------|-------------------------+
         |                                         |                |
external |                                         |                |
service  |                                         v                |
         |      +-[ index.cds : s4.simple.Customers ]---------------|-------------------------+
         |      |                                                   |                         |
         |      |  entity Customers as projection on API_BUSINESS_PARTNER.A_BusinessPartner { |
         |      |    key BusinessPartner as ID,                                               |
         |      |    BusinessPartnerFullName as name             <--+                         |
         |      |  }                                                |                         |
         |      |                                                   |                         |
         +--    +---------------------------------------------------|-------------------------+
                                                   |                |
                                                   |            PROJECTION
                                                   v                |
         +--    +-[ mashup.cds : integrate ]------------------------|-------------------------+
         |      |                                                   |                         |
         |   +---- extend service IncidentsService with {           |                         |
         |   |  |    entity Customers as projection on s4.simple.Customers;                   |
         |   |  |  }                                                                          |
         |   |  |                                                                             |
         |   |  +-----------------------------------------------------------------------------+
         |   |                                     |
service  |   |                                     |
 layer   |   |                                     v
         |   |  +-[ incidents-service.cds : IncidentsService ]--------------------------------+
         |   |  |                                                                             |
         |   +---> service IncidentsService {                                                 |
         |      |    entity Incidents as projection on incmgt.Incidents; --------------+      |
         |      |    entity Appointments as projection on incmgt.Appointments;         |      |
         |      |    entity ServiceWorkers as projection on incmgt.ServiceWorkers;     |      |
         |      |  }                                                                   |      |
         |      |                                                                      |      |
         +--    +----------------------------------------------------------------------|------+
                                                   ^                                   |
                                                   |                                   |
                                                   |                                   |
         +--    +-[ schema.cds : Incidents, Appointments, etc ]------------------------|------+
         |      |                                                                      |      |
         |      |  entity Incidents : cuid, managed {                               <--+      |
         |      |    title: String @title : 'Title';                                          |
  db     |      |    ...                                                                      |
 layer   |      |    service: Association to Appointments;                                    |
         |      |  }                                                                          |
         |      |                                                                             |
         |      |  entity Appointments {                                                      |
         |      |    ...                                                                      |
         |      |  }                                                                          |
         +--    +-----------------------------------------------------------------------------+
```

## Create an association between Customers and Incidents entities

Incidents on their own don't make much sense. What we need to make this service more useful is to be able to associate incidents with customers. Let's do that now.

👉 Open the `srv/mashup.cds` file and add another `extends` section (below the one that's already there) as follows:

```cds
extend incmgt.Incidents with {
  customer : Association to s4.simple.Customers;
}
```

👉 Think about what this `extend` section is doing. Using the diagram above, can you identify what entities, from which levels, are being connected?

### Check the effect of this association on the existing service

What effect has this new association had? Let's check.

👉 Make sure your CAP server has restarted due to the change (your `cds watch --profile sandbox` process is still running, right?) and visit the `Incidents` entity set at <http://localhost:4004/incidents/Incidents>. Check the individual entities in the response. Here's one of them, for example:

```json
{
  "ID": "2b23bb4b-4ac7-4a24-ac02-aa10cabd842c",
  "createdAt": "2023-02-02T14:48:42.252Z",
  "createdBy": "anonymous",
  "modifiedAt": "2023-02-02T14:48:42.252Z",
  "modifiedBy": "anonymous",
  "title": "Broomstick doesn't fly",
  "urgency": "high",
  "status": "closed",
  "service_ID": "1",
  "customer_ID": null,
  "IsActiveEntity": true,
  "HasActiveEntity": false,
  "HasDraftEntity": false
}
```

There's a new property in this (and all other) entities: `customer_ID`. 

> Of course, this is a new property, for the association, and the data in the CSV files that are used to seed the service don't contain any such associations, so the value for this property in each entity is `null`. 


👉 Now head on over to the service metadata at <http://localhost:4004/incidents/$metadata> and find the definition of the `Incidents` entity type as it appears in this EDMX format. It should look something like this:

```xml
<EntityType Name="Incidents">
  <Key>
    <PropertyRef Name="ID"/>
    <PropertyRef Name="IsActiveEntity"/>
  </Key>
  <Property Name="ID" Type="Edm.Guid" Nullable="false"/>
  <Property Name="createdAt" Type="Edm.DateTimeOffset" Precision="7"/>
  <Property Name="createdBy" Type="Edm.String" MaxLength="255"/>
  <Property Name="modifiedAt" Type="Edm.DateTimeOffset" Precision="7"/>
  <Property Name="modifiedBy" Type="Edm.String" MaxLength="255"/>
  <Property Name="title" Type="Edm.String"/>
  <Property Name="urgency" Type="Edm.String"/>
  <Property Name="status" Type="Edm.String"/>
  <NavigationProperty Name="conversation" Type="Collection(IncidentsService.Conversation)" Partner="up_">
    <OnDelete Action="Cascade"/>
  </NavigationProperty>
  <NavigationProperty Name="service" Type="IncidentsService.Appointments">
    <ReferentialConstraint Property="service_ID" ReferencedProperty="ID"/>
  </NavigationProperty>
  <Property Name="service_ID" Type="Edm.String"/>
  <NavigationProperty Name="customer" Type="IncidentsService.Customers">
    <ReferentialConstraint Property="customer_ID" ReferencedProperty="ID"/>
  </NavigationProperty>
  <Property Name="customer_ID" Type="Edm.String" MaxLength="10"/>
  <NavigationProperty Name="urgency_" Type="IncidentsService.Incidents_urgency">
    <ReferentialConstraint Property="urgency" ReferencedProperty="value"/>
  </NavigationProperty>
  <NavigationProperty Name="status_" Type="IncidentsService.Incidents_status">
    <ReferentialConstraint Property="status" ReferencedProperty="value"/>
  </NavigationProperty>
  <Property Name="IsActiveEntity" Type="Edm.Boolean" Nullable="false" DefaultValue="true"/>
  <Property Name="HasActiveEntity" Type="Edm.Boolean" Nullable="false" DefaultValue="false"/>
  <Property Name="HasDraftEntity" Type="Edm.Boolean" Nullable="false" DefaultValue="false"/>
  <NavigationProperty Name="DraftAdministrativeData" Type="IncidentsService.DraftAdministrativeData" ContainsTarget="true"/>
  <NavigationProperty Name="SiblingEntity" Type="IncidentsService.Incidents"/>
</EntityType>
```

The relevant part of this entity type definition that has now appeared for this association, is this combination of `NavigationProperty` and `Property`:

```xml
<NavigationProperty Name="customer" Type="IncidentsService.Customers">
  <ReferentialConstraint Property="customer_ID" ReferencedProperty="ID"/>
</NavigationProperty>
<Property Name="customer_ID" Type="Edm.String" MaxLength="10"/>
```

Adding this new association seems to have achieved what we need. Let's continue.


## Summary

At this point ...

## Further reading

* ...

---

## Questions

If you finish earlier than your fellow participants, you might like to ponder these questions. There isn't always a single correct answer and there are no prizes - they're just to give you something else to think about.

1. The name of the new property that appeared in each `Incidents` entity was `customer_ID`. Where does that name (especially the `_ID` part) come from? This name appears as the name of the new `Property` element in the `Incidents` entity type definition in the metadata too, and there, there's a value of `10` for the `MaxLength` attribute. Where is that coming from?

---

[Next exercise](../DIRNAME/)
