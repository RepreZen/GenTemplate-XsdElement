==================================================
GenTemplate: XSDElement
==================================================

To quickly find the files mentioned here in RepreZen API Studio, use
the Open Resource Dialog: Ctrl+Shift+R

MODIFYING THIS GENTEMPLATE
--------------------------

To customize the output created by this GenTemplate, modify this file:

   src/main/java/com.modelsolv.generators.xtend.template.xSDElement/MainTemplate.xtend

To change the name of the output file, modify the value of the
"outputFile" property in this file:

  /src/main/java/com.modelsolv.generators.xtend.template.xSDElement/config.json

Note that you can use "${zenModel.name}" in the "outputFile" property
to make your output file have the same name as your source model,
adding an appropriate file extension.

If you want to generate additional output files, you can do so by
making copies of the generated MainTemplate.xtend file, changing
"MainTemplate" to some other name, and then updating the config.json
file to include an entry for your new template.

Consult the RepreZen Documentation site at http://docs.reprezen.com
for more information.
