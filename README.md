# SIMOD_SWE

A model for assessing the impact of policy change in organ donation systems; case study: Sweden.

## AGENTS
* Patients: here called donors since only patients who die are considered in the model.
Donors have different states, describing them with respect to organ donation.
    * States are: possible, potential, elegible, actual, and deceased without donation (no-donation).

* STAFF: Hospital staff responsible for donation procedures.
They are tasked with discovering potential donors, contacting the TCs when death is inevitable and guiding the donation process.

* TC: Transplant Coordinators. They coordinate the process from donation (ICU) to transplantation (Transplant Hospitals) according to supply and demand. They are responsible for:
    * contacting Transplant Surgeons (not modeled), who establish the medical viability and
    * investigating consent via the registry and families of the deceased (Potential Donors).

* Patches: ICUs, Intensive Care Units, generated via the map and according to the number of public ICU in the country.

## SLIDERS AND INTERFACE

* Population
    * total_population: the total population of the country
    * bd_rate: the rate of brain death, obtained via ICD-10 codes explaining actual donor diagnosis

* Infrastructure
    * Staff: the amount of specialised Organ Donation Staff which is distributed across ICUs
    * n-icus: the amount of ICUs active in the country

* Interventions
  * Best Practice TC: sets the average TC contact rate from the national average (2015-2023) to the local best performers.
  * Best Practices Donation: sets the average Medical Viability and Consent rate from the national average (2015-2023) to the local best performer hospitals.

* Policy
  * Current Policy: sets all inputs to 2023's values.
  * ICOD: simulates donor pool expansion.

## THINGS TO NOTICE

Notice the plot of yearly pmp and its reaction to slider value changes.
Notice the Donor state plot for insights into the effect of policies and interventions on the functioning of the donation system as a whole.

## THINGS TO TRY

Modify the value of Staff, hit Setup and run the simulation, compare Donor States to previous runs.

## EXTENDING THE MODEL

This model can be expanded with more agents e.g. ORGAN TYPES, DONOR DEMOGRAPHICS, POPULATION CHANGES etc.

## NETLOGO FEATURES

The function _random-poisson_ is used to simulate fluctuations in donor pool.


## CREDITS AND REFERENCES

Developed 2025 by Bertilla Fabris, Malmö University, Department of Computer Science and Media Technology. Supervisors: Fabian Lorig and Jason Tucker.
