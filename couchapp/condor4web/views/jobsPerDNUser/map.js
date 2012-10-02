function(doc) {
	var data = doc['data'];
	if (data.JobStatus == ' 1 ') {
		emit("fdp", Null);
	}
  emit([data.dn, data.local_user], data.JobStatus );
}
