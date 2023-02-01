using { acme.incmgt } from '../db/schema';

service IncidentsService {
  entity Incidents      as projection on incmgt.Incidents;
  entity Appointments   as projection on incmgt.Appointments;
  entity ServiceWorkers as projection on incmgt.ServiceWorkers;
}
