function std_noNaN = std_omitNaN(A)
    std_noNaN = std(A,"omitmissing");
end