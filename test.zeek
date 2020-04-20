type MyRecord: record{
	url: string;
	reply_code: count;
};

global Response: table[addr] of set[MyRecord];
global Interval: table[int] of time;
global index: int = 0;
global mark: int = 0; # Index of last end of one interval

event http_reply(c: connection, version: string, code: count, reason: string) {
	local orig_addr: addr = c$id$orig_h;
	local New_record = MyRecord($url = c$http$uri, $reply_code = code);
	local begin: time = c$start_time; 
	Interval[index] = begin;
	local period: double = |Interval[index]|-|Interval[mark]|;
	local totalresp: int = 0; #total response number
	local totalnum: int = 0; #total 404 number
	local uninum: int = 0; #unique 404 number
	local totalratio: double = 0.0; #total 404 ratio
	local uniratio: double = 0.0; #unique 404 ratio
	
	#record all orig_h，url,code
	if(period <= |10min|){
		if(orig_addr in Response){
			add Response[orig_addr][New_record];
		}
		else{
			Response[orig_addr] = set(New_record);
		}
	}
	
	#another test
	if(period > |10min|){ 
		local url_404: set[string]; #record url of 404	
		mark = index - 1;
		for(orig_addr in Response){
			for(re in Response[orig_addr]){
				totalresp = totalresp + 1;
				if(re$reply_code == 404){
					totalnum = totalnum + 1;
					add url_404[re$url];
				}
			}
			uninum = |url_404|;
			totalratio = totalnum / totalresp;
			uniratio = uninum / totalnum;
			if(totalnum > 2){
				if(totalratio > 0.2){
					if(uniratio > 0.5){
						print fmt("%s is a scaner with %d scan attemps on %d urls",orig_addr,totalnum,uninum);
					}
				}
			}
			for(url in url_404){
				delete url_404[url];
			}
			delete Response[orig_addr];
		}
		Response[orig_addr] = set(New_record);
	}
	index = index + 1;
}

