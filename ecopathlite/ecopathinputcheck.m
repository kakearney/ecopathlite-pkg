function A = ecopathinputcheck(A, warnoff)
%ECOPATHINPUTCHECK Checks and fixes input in an Ewe input structure
% 
% B = ecopathinputcheck(A)
% B = ecopathinputcheck(A, warnoff)
%
% This function checks an Ewe input structure for proper dimensions and to
% verify certain values.  If incorrect values are found (for example,
% non-zero values for a primary producer's consumption/biomass ratio), the
% values are corrected.
%
% A note on multi-stanza groups: As noted in calcstanza.m, I do not always
% exactly reproduce the values of B and QB seen in EwE6.  For this reason,
% this function checks that multi-stanza group values are within 0.05% of
% the values calculated by my algorithm.  If B or QB data are missing for
% non-leading stanzas, that data is filled in.  If a stanza group has
% a biomass value outside the 0.05% error range, the biomass values for all
% stanzas of that particular group are recalculated and replaced; likewise
% for QB values.  Otherwise, they are left alone.
%
% Input variables:
%
%   A:          Ewe input structure
%
%   warnoff:    logical scalar.  If true, no warnings are issued when
%               corrections are made to the structure.  Default: false.
%
% Output variables:
%
%   B:          structure identical to A but with corrections made if
%               necessary.

% Copyright 2008-2015 Kelly Kearney

if nargin < 2
    warnoff = false;
end

if ~isscalar(A)
    error('Input structure must be scalar');
end

%----------------------------
% Check sizes
%----------------------------

if ~all(cellfun(@(x) isscalar(x) && isnumeric(x), {A.ngroup, A.ngear, A.nlive}))
    error('ngroup, nlive, and ngear must be numeric scalars');
end

group1 = {'areafrac', 'b', 'pb', 'qb', 'ee', 'ge', 'gs', 'dtImp', 'bh', ...
          'pp', 'immig', 'emig', 'emigRate', 'ba', 'baRate'};
group1size = cellfun(@(x) size(A.(x)), group1, 'uni', 0);


if ~isequal([A.ngroup 1], group1size{:})
    errlist = sprintf('  %s, %s, %s, %s, %s, %s, %s, %s,\n', group1{:});
    errlist(end-1:end) = [];
    error('The following fields must be ngroup x 1 vectors: \n%s', errlist);
end

if ~isequal([A.ngroup A.ngroup-A.nlive], size(A.df))
    error('df must be ngroup x ndet array');
end

if ~isequal([A.ngroup A.ngroup], size(A.dc))
    error('dc must be ngroup x ngroup array');
end

if ~isequal([A.ngroup A.ngear], size(A.landing), size(A.discard))
    error('landing and discard must be ngroup x ngear arrays');
end

if ~isequal([A.ngear A.ngroup-A.nlive], size(A.discardFate))
    error('discardFate must be ngear x ndet array');
end

%----------------------------
% Check content
%----------------------------

hasdtimp = (1:A.ngroup)' <= A.nlive & A.dtImp > 0;
if any(hasdtimp)
    if ~warnoff
        warning('Non-zero values found for detritus import of live groups;\n values have been reset to 0');
    end
    A.dtImp(hasdtimp) = 0;
end

nandtimp = (1:A.ngroup)' > A.nlive & isnan(A.dtImp);
if any(nandtimp)
    if ~warnoff
        warning('NaN found in detritus import, replacing with 0');
    end
    A.dtImp(nandtimp) = 0;
end

epfields = {'b', 'pb', 'qb', 'ee', 'ge', 'bh'};
for ifield = 1:length(epfields)
    isneg = (A.(epfields{ifield}) < 0);
    if any(isneg)
        if ~warnoff
            warning('Negative placeholders found in %s field, replacing with NaN', fields{ifield});
        end
        A.(epfields{ifield})(isneg) = NaN;
    end
end
    
qbnotzero = A.pp >= 1 & A.qb ~= 0;
if any(qbnotzero)
    if ~warnoff
        warning('Non-zero value found for a producer or detrital Q/B, replacing with zero');
    end
    A.qb(qbnotzero) = 0;
end

genotzero = A.pp >= 1 & A.ge ~= 0;
if any(genotzero)
    if ~warnoff
        warning('Non-zero value found for a producer or detrital GE, replacing with zero');
    end
    A.ge(genotzero) = 0;
end

gsnotzero = A.pp >= 1 & A.gs ~= 0;
if any(gsnotzero)
    if ~warnoff
        warning('Non-zero value found for a producer or detrital GS, replacing with zero');
    end
    A.gs(gsnotzero) = 0;
end

pbnotzero = A.pp == 2 & A.pb ~= 0;
if any(pbnotzero)
    if ~warnoff
        warning('Non-zero value found for detrital P/B, replacing with zero');
    end
    A.pb(pbnotzero) = 0;
end

%----------------------------
% Check Ecosim-related 
% content (optional fields)
%----------------------------

groupinfo = {'maxrelpb', 'maxrelfeed', 'feedadj', 'fracsens', ...
            'predeffect', 'densecatch', 'qbmaxqb0', 'switchpower'};

% Check group info sizes.  Group info fields are listed in GUI without
% detritus, so input coming from these tables may be too short. 

for ifd = 1:length(groupinfo)
    if isfield(A, groupinfo{ifd})
        if isequal(size(A.(groupinfo{ifd})), [A.ngroup-1 1])
            A.(groupinfo{ifd}) = [A.(groupinfo{ifd}); zeros(A.ngroup-A.nlive,1)];
        elseif ~isequal(size(A.(groupinfo{ifd})), [A.ngroup 1])
            error('%s field must be ngroup x 1 vector', groupinfo{ifd});
        end
    end
end
  
% Max rel. P/B should be 0 for non-producers
    
if isfield(A, 'maxrelpb')
    maxpbnotzero = A.pp ~= 1 & A.maxrelpb ~= 0;
    if any(maxpbnotzero)
        if ~warnoff
            warning('Non-zero max rel P/B found for non-producers, replacing with 0');
        end
        A.maxrelpb(maxpbnotzero) = 0;
    end
end

% Other group info should be 0 for producers and detritus

for ifd = 2:length(groupinfo)
    if isfield(A, groupinfo{ifd})
        ginotzero = A.pp ~= 0 & A.(groupinfo{ifd}) ~= 0;
        if any(ginotzero)
            if ~warnoff
                warning('Non-zero %s found for producer or detritus, replacing with 0', groupinfo{ifd});
            end
            A.(groupinfo{ifd})(ginotzero) = 0;
        end
    end
end

% kv should be 0 where dc is 0

if isfield(A, 'kv')
    if ~isequal(size(A.kv), [A.ngroup A.ngroup])
        error('kv field mst be ngroup x ngroup array');
    end
    kvnotzero = A.dc == 0 & A.kv ~= 0;
    if any(kvnotzero(:))
        if ~warnoff
            warning('Non-zero kv found for non-feeding links, replacing with 0');
        end
        A.kv(kvnotzero) = 0;
    end
end
    
%----------------------------
% Check multi-stanza values
%----------------------------

% Check that multi-stanza group values are consistent with each other if
% filled in already.  Fill in if not.

if isfield(A, 'stanzadata')
    Tmp = calcstanza(A);
    
    % If non-leading stanza group data was missing, fill it in (all or
    % nothing... if one stanza-group is missing, all other stanzas of that
    % group need to be recalculated)
    
    bfill = isnan(A.b) & ~isnan(Tmp.b);
    bchange = ismember(A.stanza, unique(A.stanza(bfill)));
    A.b(bchange) = Tmp.b(bchange);
    qfill = isnan(A.qb) & ~isnan(Tmp.qb);
    qchange = ismember(A.stanza, unique(A.stanza(qfill)));
    A.qb(qchange) = Tmp.qb(qchange);
    
    % Check for any other changes.  Keep original data if it's within my
    % tolerance (meaning probably correct, just picking up the differences
    % between my implementation of the staza calculations vs EwE6's
    % implementation).  If it's further off, assume incorrect data, and
    % replace data for all stanzas of that group.
    
    berr = (Tmp.b - A.b)./A.b;
    qerr = (Tmp.qb - A.qb)./A.qb;
    
    tol = 0.005;
    bwrong = abs(berr) > tol;
    qwrong = abs(qerr) > tol;
    if any([bwrong; qwrong])
        warning('Multi-stanza group data inconsistent; replacing');
        bchange = ismember(A.stanza, unique(A.stanza(bwrong)));
        A.b(bchange) = Tmp.b(bchange);
        qchange = ismember(A.stanza, unique(A.stanza(qwrong)));
        A.qb(qchange) = Tmp.qb(qchange);
    end    
end


    
    
    

