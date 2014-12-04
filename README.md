# Ecopathlite: A Matlab implementation of the Ecopath algorithm

Ecopath with Ecosim is a popular ecosystem modeling tool, used primarily in the fisheries modeling community. The original software and documentation for this tool can be found here: www.ecopath.org.

Ecopath is used to calculate a snapshot of an ecosystem, including the biomass of all functional groups (living groups, fishing gears, and detrital pools) and the fluxes between these groups. This Matlab function is designed to complement the original software by providing a quick, easy-to-automate alternative to the GUI-based software available from the link above.
In addition to reproducing the main Ecopath algorithm (ecopathlite.m), this package includes two additional top-level functions:

- mdb2ewein.m: Imports EwE6 database files to Matlab for use with ecopathlite.m
- createensemble.m: Generates an ensemble of Ecopath parameter sets based on a starting model and parameter uncertainty (i.e. pedigree) values.