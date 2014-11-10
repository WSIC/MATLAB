function privateFcn = getPrivateFcn(privateDir,fcnName)
  oldDir = cd(privateDir);         %# Change to the private directory
  privateFcn = str2func(fcnName);  %# Get a function handle
  cd(oldDir);                      %# Change back to the original directory
end