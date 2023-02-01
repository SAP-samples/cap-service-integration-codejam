using { IncidentsService, acme.incmgt.Incidents, cuid } from '../srv/incidents-service';

annotate cuid:ID with @title: 'ID';
@odata.draft.enabled
annotate IncidentsService.Incidents with @(UI : {

  // For Lists of Incidents
  SelectionFields : [ urgency, status, service.type ],
  LineItem : [
    { Value: title },
    { Value: urgency, Criticality : #Critical, CriticalityRepresentation : #WithoutIcon, },
    { Value: status },
    { Value: service.type },
  ],

  // Information for the header area of Details Pages
  HeaderInfo : {
    TypeName     : 'Incident',
    TypeNamePlural : 'Incidents',
    TypeImageUrl   : 'sap-icon://alert',
    Title      : { Value: title },
  },

  // Facets for additional object header information (shown in the object page header)
  HeaderFacets : [{
    $Type  : 'UI.ReferenceFacet',
    Target : '@UI.FieldGroup#HeaderGeneralInformation'
  }],

  // Facets for Details Page of Incidents
  Facets : [
    { Label: 'Overview', ID:'OverviewFacet', $Type: 'UI.CollectionFacet', Facets : [
      { Label: 'General Information', $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#GeneralInformation' },
      { Label: 'Details', $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#IncidentDetails' },
    ]},
    { Label: 'Conversation', $Type: 'UI.ReferenceFacet', Target: 'conversation/@UI.LineItem' }
  ],

  FieldGroup #HeaderGeneralInformation : {
    Data : [
      { Value: urgency },
      { Value: status },
      { Value: service.type },
      { Label: 'Worker', $Type  : 'UI.DataFieldForAnnotation', Target : 'service/worker/@Communication.Contact' }
    ]
  },

  FieldGroup #IncidentDetails : {
    Data : [
      { Value: ID },
      { Value: title },
     ]
  },

  FieldGroup #GeneralInformation: {
    Data : [
      { Value: urgency, },
      { Value: service.type },
      { Value: status, },
    ],
  },

});


annotate IncidentsService.Conversation with @(UI : {

  LineItem : [
    { Value: timestamp },
    { Value: author },
    { Value: message }
  ],

  HeaderInfo : {
    TypeName       : 'Message',
    TypeNamePlural : 'Messages',
    Title          : { Value: message },
    Description    : { Value: timestamp },
  },

  Facets : [
    { Label: 'Details', $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#MessageDetails' },
  ],
  FieldGroup #MessageDetails : {
    Data: [
      { Value: message }
    ]
  }
});


annotate IncidentsService.ServiceWorkers with @(Communication.Contact : {
  fn   : name,
  kind : #individual,
  role : role,
});


annotate IncidentsService.Appointments with @(UI : {
  LineItem : [
    { Value: start_date },
    { Value: end_date },
    { Value: worker.name, Label : 'Assigned' }
  ]
});



// Reusable aspect for enums-based Value Helps
aspect EnumsCodeList @cds.autoexpose @cds.odata.valuelist {
  key value: String @Common: { Text: label, TextArrangement: #TextOnly };
  label : localized String;
  descr : localized String;
}

// Value Help for Incidents.urgency
define entity acme.incmgt.Incidents_urgency : EnumsCodeList {}; // REVISIT: Should be Incidents.urgency but this creates confusion with Incidents:urgency
extend entity Incidents with {
  urgency_: Association to acme.incmgt.Incidents_urgency on urgency_.value = urgency; // REVISIT: we should get rid of unstable element order messages
  extend urgency with @Common : { // REVISIT: we should also support keyword annotate here
    Text: urgency_.label, TextArrangement : #TextOnly,
    ValueListWithFixedValues,
    ValueList: {
      CollectionPath:'Incidents_urgency',
      Parameters:[
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: urgency, ValueListProperty: 'value' },
      ],
    },
  };
}

// Value Help for Incidents.status
define entity acme.incmgt.Incidents_status : EnumsCodeList {}; // REVISIT: Should be Incidents.status but this creates confusion with Incidents:status
extend entity Incidents with {
  status_: Association to acme.incmgt.Incidents_status on status_.value = status; // REVISIT: we should get rid of unstable element order messages
  extend status with @Common : { // REVISIT: we should also support keyword annotate here
    Text: status_.label, TextArrangement : #TextOnly,
    ValueListWithFixedValues,
    ValueList: {
      CollectionPath:'Incidents_status', // REVISIT: Should be Incidents.Status but this doesn't work
      Parameters:[
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: status, ValueListProperty: 'value' },
      ],
    },
  };
}


// REVISIT: this is needed to make the 'conversation/@UI.LineItem' path work
extend service IncidentsService with {
  entity Conversation as projection on Incidents.conversation;
}
