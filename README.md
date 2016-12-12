# Decisions From Experience
---
Matlab code relying on [Psychtoolbox 3](http://psychtoolbox.org) to execute an experiment.

- code_v1 --> first version of the code, all in one script
- code_v2 --> separate scripts, more tidy
- code_v2 --> same as v2 but with improved timing
- code_v4 --> same as v3 but with EEG markers
- code_v5 --> same as v4 functionally ... but in a different style. Also, requires Statistics Toolbox (for binornd function)
- code v6 --> bigger stims, working markers, in SP: decide for sample/choice using the down arrow. 

For more information, [read the documentation!](documentation/DFE_docu.pdf)

## EEG

For sending EEG markers in the experiment, you can use the [io64 module](http://apps.usd.edu/coglab/psyc770/IO64.html) - however, you will need Windows and a parallel port for that.