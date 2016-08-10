/*******************************************************************************
 * Copyright © 2013, 2016 Modelsolv, Inc.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property
 * of ModelSolv, Inc. See the file license.html in the root directory of
 * this project for further information.
 *******************************************************************************/
package com.modelsolv.reprezen.gentemplates.xsdelement.xtend

import com.google.common.base.Splitter
import com.google.common.base.Strings
import com.google.common.collect.Lists
import com.modelsolv.reprezen.gentemplates.common.services.CommonServices
import com.modelsolv.reprezen.restapi.Method
import com.modelsolv.reprezen.restapi.ResourceAPI
import com.modelsolv.reprezen.restapi.ResourceDefinition
import com.modelsolv.reprezen.restapi.ServiceDataResource
import com.modelsolv.reprezen.restapi.TypedMessage
import com.modelsolv.reprezen.restapi.ZenModel
import com.modelsolv.reprezen.restapi.datatypes.DataModel
import com.modelsolv.reprezen.restapi.datatypes.PrimitiveType
import com.modelsolv.reprezen.restapi.datatypes.ReferenceProperty
import com.modelsolv.reprezen.restapi.datatypes.SingleValueType
import com.modelsolv.reprezen.restapi.datatypes.Structure
import com.modelsolv.reprezen.restapi.datatypes.UserDefinedType
import java.util.Collection
import java.util.LinkedList
import java.util.Set
import org.eclipse.emf.ecore.EObject
import com.modelsolv.reprezen.restapi.Documentable
import com.modelsolv.reprezen.gentemplates.common.xtend.ZenModelHelper
import com.modelsolv.reprezen.restapi.datatypes.Constraint
import com.modelsolv.reprezen.restapi.datatypes.LengthConstraint
import com.modelsolv.reprezen.restapi.datatypes.RegExConstraint
import com.modelsolv.reprezen.restapi.datatypes.ValueRangeConstraint

class XMLSchemaHelper {
	extension ZenModelHelper zenModelHelper = new ZenModelHelper
	
	// TODO: Use Guava's 15 Escaper after migration 
	def String escapeXml(String source) {
		source.replaceAll("&", "&amp;").replaceAll("\"", "&quot;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").
			replaceAll("\'", "&apos;");
	}

	def <T extends EObject> T getEContainer(EObject ele, Class<T> type) {
		CommonServices::getContainerOfType(ele, type)
	}

	def <T> Collection<T> putAll(Iterable<T> iterable, Class<T> _class) {
		val Collection<T> result = new LinkedList<T>
		iterable.forEach[result.add(it)]
		return result
	}

	def ZenModel zenModel(EObject obj) {
		obj.getEContainer(ZenModel)
	}

	def dispatch String namespace(DataModel dataModel) {
		schemaRoot(dataModel.zenModel) + dataModel.name.toLowerCase()
	}

	def dispatch String namespace(ResourceAPI resourceAPI) {
		schemaRoot(resourceAPI.zenModel) + resourceAPI.name.toLowerCase()
	}

	def String schemaRoot(ZenModel zenModel) {
		val uriFragment = if (zenModel.namespace.nullOrEmpty) {
				'http://modelsolv.com/reprezen/schemas'
			} else {
				'http://' + reverseNamespace(zenModel.namespace)
			}
		uriFragment + "/" + zenModel.name.toLowerCase + "/"
	}

	def String reverseNamespace(String namespace) {
		val int idx = namespace.indexOf('.')
		if(idx == -1) namespace else Lists.reverse(Splitter.on('.').split(namespace).toList).join('.')
	}

	def nsPrefix(DataModel dataModel, ResourceAPI resourceAPI) {
		if (dataModel != null) {
			if (resourceAPI.zenModel == dataModel.zenModel)
				dataModel.name.toFirstLower
			else {
				val String alias = getAliasForDataModel(resourceAPI.zenModel, dataModel)
				if(Strings.isNullOrEmpty(alias)) dataModel.getShortestUniqueName(resourceAPI) else alias
			}
		}
	}

	def dispatch String nsPrefix(ResourceAPI resourceAPI) {
		if (resourceAPI != null)
		  resourceAPI.name.toLowerCase + ""
	}

	def dispatch String nsPrefix(ServiceDataResource dataResource) {
		nsPrefix(dataResource.getInterface)
	}

	def xsdFileName(DataModel dataModel, ZenModel zenModel) {
		if (zenModel == dataModel.zenModel)
			dataModel.name.toFirstLower + ".xsd"
		else {
			val ZenModel model = dataModel.zenModel
			val String woNsName = model.name.toFirstLower + "-" + dataModel.name.toFirstLower + ".xsd"
			if(model.namespace.nullOrEmpty) woNsName else model.namespace.toFirstLower.replaceAll("\\.", "-") + "-" +
				woNsName
		}
	}

	def xsdFileName(ResourceAPI resourceAPI) {
		resourceAPI.name.toFirstLower + ".xsd"
	}

	def dispatch complexTypeName(Structure complexType) {
		complexType.name.toFirstUpper
	}

	def dispatch complexTypeName(ServiceDataResource dataResource) {
		dataResource.name.toFirstUpper
	}

	def dispatch xsdElementName(Structure complexType) {
		complexType.name.toFirstLower
	}

	def dispatch xsdElementName(ServiceDataResource dataResource) {
		dataResource.name.toFirstLower
	}

	def dispatch String complexTypeQName(TypedMessage message) {
		val resourceType = message.resourceType
		complexTypeQName(toServiceDataResource(resourceType))
	}

	def dispatch String complexTypeQName(ServiceDataResource dataResource) {
		if(dataResource == null) null else nsPrefix(dataResource) + ":" + complexTypeName(dataResource)
	}

	def private toServiceDataResource(ResourceDefinition resource) {
		if(resource instanceof ServiceDataResource) (resource as ServiceDataResource) else null
	}

	// FIXME support nested data types
	def protected DataModel getInterfaceDataModel(Structure complexType) {
		complexType.eContainer as DataModel
	}

	def getInterface(ServiceDataResource dataResource) {
		if(dataResource == null) null else dataResource.getEContainer(ResourceAPI)
	}

	def Iterable<SingleValueType> getUsedTypes(ZenModel zenModel) {
		CommonServices.getUsedSimpleTypes(zenModel)
	}

	def Iterable<SingleValueType> getUsedTypes(ResourceAPI resourceAPI) {
		CommonServices.getUsedSimpleTypes(resourceAPI)
	}

	def getAliasForDataModel(ZenModel zenModel, DataModel dataModel) {
		zenModel.getImportDeclaration(dataModel).alias
	}

	def getImportDeclaration(ZenModel zenModel, DataModel dataModel) {
		if(zenModel == dataModel.zenModel) null else zenModel.imports.findFirst[it.importedNamespace == dataModel.getFQN]
	}

	def getFQN(DataModel dataModel) {
		val ZenModel zenModel = dataModel.zenModel
		val String woNsName = zenModel.name + "." + dataModel.name
		if(Strings.isNullOrEmpty(zenModel.namespace)) woNsName else zenModel.namespace + "." + woNsName
	}

	def getShortestUniqueName(DataModel dataModel, ResourceAPI resourceAPI) {
		var String result
		var Set<DataModel> dataModels = resourceAPI.getUsedDataModels.filter [
			(
                    (resourceAPI.zenModel == it.zenModel) ||
				resourceAPI.zenModel.getImportDeclaration(it).alias == null
                ) && (it.name == dataModel.name)
		].filter[it != dataModel].toSet

		//dataModels.remove(dataModel)
		if (dataModels.empty)
			result = dataModel.name
		else {
			if (!dataModels.exists[it.zenModel.name == dataModel.zenModel.name])
				result = dataModel.zenModel.name + "." + dataModel.name
			else
				result = dataModel.getFQN
		}

		return result
	}

	def getNameOfCorrespondingComplexType(ReferenceProperty refProperty, ResourceAPI resourceAPI) {
		val defaultResource = resourceAPI.getDefaultResource(refProperty.type, refProperty.maxOccurs == 1)
		if(defaultResource == null) complexTypeName(refProperty.type) else complexTypeName(defaultResource)
	}

	def getTypeName(UserDefinedType userDefinedType) {
		val prefix = if(userDefinedType.baseType instanceof PrimitiveType) "xs:" else ""
		return prefix + userDefinedType.baseType.name
	}

	def dispatch Iterable<DataModel> getUsedDataModels(ResourceAPI resourceAPI) {
		resourceAPI.getUsedTypes.map[it.getEContainer(DataModel)].filter[it != null].toSet
	}

	def dispatch Iterable<DataModel> getUsedDataModels(ZenModel zenModel) {
		zenModel.resourceAPIs.map[it.usedDataModels].flatten.toSet
	}

	def getParentResourceDefinition(TypedMessage message) {
		message.getEContainer(Method).getEContainer(ResourceDefinition)
	}

	def String generateXSDDoc(Documentable doc) {
		val String docText = getDocumentation(doc)
		val String escapedDoc = docText.replaceAll("[\r\n]+", " ").replaceAll("[\n]+", " ").replaceAll("([\"\\\\])", "\\\\$1").trim()
		if (!escapedDoc.nullOrEmpty) {
			'''
				<xs:annotation>
					<xs:documentation>
						<!-- «escapedDoc» -->
					</xs:documentation>
				</xs:annotation>
			'''
		}
	}
	
	def generateRestriction(String baseTypeName, Iterable<Constraint> constraints) {
		'''
			<xs:restriction base="«baseTypeName»">
			«IF !constraints.nullOrEmpty»
				«FOR constraint : constraints SEPARATOR ""»
					«IF constraint instanceof LengthConstraint»
						«val LengthConstraint c = constraint as LengthConstraint»
						«IF c.maxLength != 0 && c.maxLength == c.minLength»
							<xs:length value="«c.minLength»"/>
						«ELSE»
							«IF (c.minLength != 0)»
								<xs:minLength value="«c.minLength»"/>
							«ENDIF»
							«IF (c.maxLength != 0)»
								<xs:maxLength value="«c.maxLength»"/>
							«ENDIF»
						«ENDIF»
					«ELSE»
						«IF constraint instanceof RegExConstraint»
							«val RegExConstraint c = constraint as RegExConstraint»
							<xs:pattern value="«escapeXml(c.pattern)»"/>
						«ELSE»
							«val ValueRangeConstraint c = constraint as ValueRangeConstraint»
							«IF c.minValueExclusive»
								<xs:minExclusive value="«c.minValue»"/>
							«ELSEIF c.minValue != null» 
								<xs:minInclusive value="«c.minValue»"/>
							«ENDIF»
							«IF c.maxValueExclusive»
								<xs:maxExclusive value="«c.maxValue»"/>
							«ELSEIF c.maxValue != null» 
								<xs:maxInclusive value="«c.maxValue»"/>
							«ENDIF»
						«ENDIF»
					«ENDIF»
				«ENDFOR»
			«ENDIF»
			</xs:restriction>
		'''
	}
}
