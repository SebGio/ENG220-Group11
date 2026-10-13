%datatable = readtable("nm-capital-appropriations-2026-10-13.csv");

CSV = "nm-capital-appropriations-2026-10-13.csv";

opts = detectImportOptions(CSV);
opts = setvartype(opts, "LegislativeSponsors", "string");   % replace with the exact column name
datatable = readtable(CSV, opts);

%appropriated, expended, and remaining balance columns
appIdx = 15;
expIdx = 18;
balIdx = 21;

cityIdx = 7;

%reathorized funds
reauthIdx = 16;
reauthAmount = datatable{:, reauthIdx};

appropriated = datatable{:, appIdx};
expended = datatable{:, expIdx};
remaining = datatable{:, balIdx};

expected = expended + remaining;

validMask = ~isnan(appropriated) & ~isnan(expended) & ~isnan(remaining);

%appropriated amount does not match expended + remaining amount
%should be empty because it should be automatically calculated by the
%system
mismatchMask = validMask & abs(appropriated - expected) > 0.01;

mismatchRows = datatable(mismatchMask, :);
mismatchRows.AmountDifference = appropriated(mismatchMask) - expected(mismatchMask);

%rows where appropriate, expended, or remaining amounts are NaN values
missingRows = datatable(~validMask, :);

% rows with negative values
negativeBalanceMask = appropriated < 0 | expended < 0 | remaining < 0;
reauthGreaterMask = reauthAmount >= expended;
negativeMask = negativeBalanceMask & ~reauthGreaterMask;
negativeRows = datatable(negativeMask, :);

%rows with no appropriated amounts but expended or remaining is > 0
reauthorizedMask = datatable{:, reauthIdx} > 0;
activeMask = expended > 0 | remaining > 0;
zeroMask = appropriated == 0 & activeMask & ~reauthorizedMask;
zeroRows = datatable(zeroMask, :);

allSuspiciousRows = datatable(mismatchMask | negativeMask | zeroMask, :);

negativeRowNums = find(negativeMask);
zeroRowNums = find(zeroMask);

idIdx = 1;

maxPoints = 60;

% Negative-value rows
if any(negativeMask)
    negIdx = find(negativeMask);
    negScore = abs(appropriated(negativeMask)) + abs(expended(negativeMask)) + abs(remaining(negativeMask));
    [~, order] = sort(negScore, 'descend');
    negIdx = negIdx(order);
    negIdx = negIdx(1:min(maxPoints, numel(negIdx)));

    negLabels = string(datatable{negIdx, idIdx});
    negVals = [appropriated(negIdx), expended(negIdx), remaining(negIdx)];

    figure('Position', [100 100 2200 600])
    b = bar(categorical(negLabels), negVals, 'grouped');
    for k = 1:numel(b)
        b(k).BarWidth = 0.95;
    end

    title("Negative Balance Projects")
    xlabel("Appropriation ID")
    ylabel("Amount")
    legend("Appropriated", "Expended", "Remaining", 'Location', 'best')
    grid on
    xtickangle(45)
    pan on
end

% Zero-appropriation rows with activity
if any(zeroMask)
    zeroIdx = find(zeroMask);
    zeroScore = expended(zeroMask);
    [~, order] = sort(zeroScore, 'descend');
    zeroIdx = zeroIdx(order);
    zeroIdx = zeroIdx(1:min(maxPoints, numel(zeroIdx)));

    zeroLabels = string(datatable{zeroIdx, idIdx});
    zeroVals = expended(zeroIdx);

    figure('Position', [150 150 1200 450])
    barh(categorical(zeroLabels), zeroVals)
    title("Top Zero-Appropriation Rows with Activity")
    xlabel("Expended Amount")
    ylabel("Appropriation ID")
    grid on
end

