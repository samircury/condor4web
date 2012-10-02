function (key, values) {
  var output = {' 1 ' : 0, ' 2 ' : 0, ' 3 ' : 0, ' 4 ' : 0, ' 5 ' : 0};
    for (var job in values) {
		var jobStatus = values[job];
	    //if (output[jobStatus] != null) {
	    //	output[jobStatus]=0;	
	    //	}
		if (output[jobStatus] != null) {
       			output[jobStatus] += 1;
		}
	}
	return output;
}
