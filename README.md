Truth-Matrix

These code samples will help you start building your own Truth Matrix.  All deployments of file MTRXHEAD will have the same format, 
however file MTRXDETL will differ because it contains the key data points that drive your business and are often hard coded in
application programs.

To deploy:
Run SQL script TRUTHMTRX.SQL, but first update the name of the schema qualifier (currently TRUTHDTA).
Compile display file TRUTHFM.
Compile maintenance program TRUTHMAINT.
Compile module TRUTHTOOL.
Create service program TRUTHTOOL, using the binder source in TRUTHTOOL.BND.
Run SQL script TRUTHTOOL to create SQL function references to the isTrue procedure.
Call program TRUTHMAINT to start defining your conditions and associated criteria.
In your application program, include /COPY member TRUTHTOOL.CPY.
Use the isTrue function in RPG or SQL.
