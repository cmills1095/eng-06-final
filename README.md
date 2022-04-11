# eng-06-final
My final project for a college class I did in 2019.
Not particularly useful but I'm pretty proud of it since the class was just supposed to be an intro to Matlab.

Uploaded to github 4/11/2022 (Version 1.6.5)
Created by Chris Mills

Note on credit: This was originally for a final project in ENG 006 at UC Davis, which was theoretically a group project, but this code was 100% written and designed by me and me alone with Z E R O input or contribution from my groupmates (I have the correspondence to prove this).

Pre-github revision history:
Originally created 11/16/19 as class "filterTrack," but evolved into its own thing. Became "track" on 11/23.
Revision 11/25 - The "set" functions no longer call setFilter, to improve filter startup time. Semi-integrated class "delayTrack"
Revision 11/26 - Fully integrated class "delayTrack". Cleaned up, added stereo functionality and "center removal."
Revision 12/2 - Added a reinitialize fxn, error validation, and now forces the input array into column format
Revision 12/4 - Changed steepness control for filters from 0.5 to 0.85, which significantly improves filter startup time. (From 6.5 to 2.5 seconds). Also added a setspeed function which allows manual input of speed
Revision 12/5 - Added whatever was needed for the Chopper GUI. This is the version that was turned in for my final project.
Revision 12/15/19 - General cleanup and commenting, made all properties private and added get functions for the relevant ones. Combined initialize and constructor fxns into one fxn called by both. Fixed bug allowing voice removal to remain active when the filter is turned on.Still working on this (need to test with other GUI's now).

Future to-do: Add stereo delay.
Possible extra features: Exponential decay feature for delay, filter steepness control for filter, pitch alteration, sample naming capability
