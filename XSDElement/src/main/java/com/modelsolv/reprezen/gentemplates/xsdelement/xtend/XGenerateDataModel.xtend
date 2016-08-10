/*******************************************************************************
 * Copyright © 2013, 2016 Modelsolv, Inc.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property
 * of ModelSolv, Inc. See the file license.html in the root directory of
 * this project for further information.
 *******************************************************************************/
package com.modelsolv.reprezen.gentemplates.xsdelement.xtend

import com.modelsolv.reprezen.generators.api.zenmodel.ZenModelExtractOutputItem
import com.modelsolv.reprezen.restapi.ZenModel
import com.modelsolv.reprezen.restapi.datatypes.DataModel
import com.modelsolv.reprezen.restapi.datatypes.EnumConstant
import com.modelsolv.reprezen.restapi.datatypes.Enumeration
import com.modelsolv.reprezen.restapi.datatypes.UserDefinedType
import java.io.File

class XGenerateDataModel extends ZenModelExtractOutputItem<DataModel> {
	extension XMLSchemaHelper = new XMLSchemaHelper

	override File getOutputFile(ZenModel zenModel, DataModel dataModel) {
		return new File(dataModel.xsdFileName(zenModel))
	}

	override String generate(ZenModel zenModel, DataModel dataModel) {
		return '''
			<xs:schema
				targetNamespace="«dataModel.namespace»"
				elementFormDefault="qualified"
				xmlns="«dataModel.namespace»"
				xmlns:tns="«dataModel.namespace»"
				xmlns:xs="http://www.w3.org/2001/XMLSchema"
				xmlns:xml="http://www.w3.org/XML/1998/namespace"
				«dataModel.generateNamespaceAdditions»
			>
			«dataModel.generateXSDDoc»
			«FOR dataType : dataModel.ownedDataTypes SEPARATOR ""»
				«IF (dataType instanceof Enumeration) || (dataType instanceof UserDefinedType)»
					«generate(dataType)»
				«ENDIF»
			«ENDFOR»
			</xs:schema>
		'''
	}

	def private generateNamespaceAdditions(DataModel dataModel) {
		'''
			xmlns:jaxb="http://java.sun.com/xml/ns/jaxb"
			jaxb:version="2.0"
		'''
	}

	def private dispatch generate(Enumeration en) {
		'''
			<xs:simpleType name="«en.name»">
			«en.generateEnumAnnotation»
				<xs:restriction base="xs:«en.baseType.name»">
					«FOR enumConstant : en.enumConstants SEPARATOR ""»
						«enumConstant.generateEnumConstant»
					«ENDFOR»
				</xs:restriction>
			</xs:simpleType>
		'''
	}

	def private dispatch generate(UserDefinedType userDefinedType) {
		'''
			<xs:simpleType name="«userDefinedType.name»">
				«generateRestriction(userDefinedType.typeName, userDefinedType.constraints)»
			</xs:simpleType>
		'''
	}

	def private generateEnumAnnotation(Enumeration en) {
		'''
			<xs:annotation>
				<xs:appinfo>
					<jaxb:typesafeEnumClass />
				</xs:appinfo>
			</xs:annotation>
		'''
	}

	def private generateEnumConstant(EnumConstant enumConstant) {
		'''
			<xs:enumeration value="«enumConstant.literalValue ?: enumConstant.integerValue»">
				«enumConstant.generateEnumConstantAnnotation»
			</xs:enumeration>
		'''
	}

	def private generateEnumConstantAnnotation(EnumConstant enumConstant) {
		'''
			<xs:annotation>
				<xs:appinfo>
					<jaxb:typesafeEnumMember name="«enumConstant.name»" />
				</xs:appinfo>
			</xs:annotation>
		'''
	}
}
