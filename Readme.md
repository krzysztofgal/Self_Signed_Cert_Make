This makefile creates self-signed certificates with RootCa.

# Usage
```make rootCA.crt``` (rootCA.key implicitly created).  
```make DOMAIN=somedomain.dev somedomain.dev.csr somedomain.dev.crt```  
or  
```make DOMAIN=somedomain.dev```  
```make DOMAIN=somedomain.dev verify-csr```  
```make DOMAIN=somedomain.dev verify-crt```

Credits to original makefile: https://gist.github.com/xenogenesi/1b2137f769aa80b6c99d573071f5d086