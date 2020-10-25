
"""

A package for taking groups of sequences and finding a sequence
that is representitive of the group via the levenshtein distance.

Note that the sequence returned may not be a meaningful sequence, For example, it
would not return a 'correcnt' DNA sequence that would be useful. 

"""


module SequenceReduction

export basic_lev, lev_update, lev_trace, lev_distance, lev_create

include("basic-lev-reduction.jl")

end # module
