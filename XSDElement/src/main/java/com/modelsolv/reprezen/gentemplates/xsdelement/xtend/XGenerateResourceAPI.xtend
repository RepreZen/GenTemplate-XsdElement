/*******************************************************************************
 * Copyright © 2013, 2016 Modelsolv, Inc.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property
 * of ModelSolv, Inc. See the file license.html in the root directory of
 * this project for further information.
 *******************************************************************************/
package com.modelsolv.reprezen.gentemplates.xsdelement.xtend

import com.google.common.collect.Iterables
import com.modelsolv.reprezen.generators.api.zenmodel.ZenModelExtractOutputItem
import com.modelsolv.reprezen.generators.api.zenmodel.ZenModelLocator
import com.modelsolv.reprezen.gentemplates.common.services.CommonServices
import com.modelsolv.reprezen.restapi.CollectionResource
import com.modelsolv.reprezen.restapi.LinkDescriptor
import com.modelsolv.reprezen.restapi.Method
import com.modelsolv.reprezen.restapi.ReferenceEmbed
import com.modelsolv.reprezen.restapi.ReferenceLink
import com.modelsolv.reprezen.restapi.ReferenceTreatment
import com.modelsolv.reprezen.restapi.ResourceAPI
import com.modelsolv.reprezen.restapi.ServiceDataResource
import com.modelsolv.reprezen.restapi.TypedMessage
import com.modelsolv.reprezen.restapi.ZenModel
import com.modelsolv.reprezen.restapi.datatypes.PrimitiveProperty
import com.modelsolv.reprezen.restapi.datatypes.ReferenceElement
import com.modelsolv.reprezen.restapi.datatypes.ReferenceProperty
import com.modelsolv.reprezen.restapi.datatypes.Structure
import java.util.Collection
import java.util.LinkedList
import org.eclipse.emf.ecore.EObject
import com.modelsolv.reprezen.restapi.PropertyRealization

class XGenerateResourceAPI extends ZenModelExtractOutputItem<ResourceAPI> {
	extension FeatureHelper = new FeatureHelper
	extension ResourceHelper = new ResourceHelper
	extension ReferenceLinkHelper = new ReferenceLinkHelper
	extension XMLSchemaHelper = new XMLSchemaHelper

	var ZenModelLocator locator

	override String generate(ZenModel zenModel, ResourceAPI resourceAPI) {

		this.locator = new ZenModelLocator(zenModel)
		context.addTraceItem('resourceAPI') //
		.withProperty('namespace', resourceAPI.namespace) //
		.withProperty('namespacePrefix', resourceAPI.nsPrefix) //
		.withPrimarySourceItem(locator.locate(resourceAPI)) //

		'''
			<xs:schema
				targetNamespace="«resourceAPI.namespace»"
				elementFormDefault="qualified"
				xmlns="«resourceAPI.namespace»"
				xmlns:tns="«resourceAPI.namespace»"
				«FOR dataModel : resourceAPI.getUsedDataModels SEPARATOR ""»
					«val nsprefix = dataModel.nsPrefix(resourceAPI)»
					xmlns:«nsprefix»="«dataModel.namespace»"
				«ENDFOR»
				xmlns:xs="http://www.w3.org/2001/XMLSchema"
				xmlns:xml="http://www.w3.org/XML/1998/namespace"
				«resourceAPI.generateNamespaceAdditions»
			>
			«resourceAPI.generateSchemaImports»
			«FOR dataModel : resourceAPI.getUsedDataModels SEPARATOR ""»
				<xs:import namespace="«dataModel.namespace»" schemaLocation="«dataModel.xsdFileName(resourceAPI.zenModel)»"/>
			«ENDFOR»
			<!-- ELEMENT AND COMPLEX TYPE DECLARATIONS FOR RESOURCE DEFINITIONS -->
			«FOR dataResource : resourceAPI.ownedResourceDefinitions SEPARATOR ""»
				«generateServiceDataResource(dataResource as ServiceDataResource, resourceAPI)»
			«ENDFOR»
			<!-- ELEMENT AND COMPLEX TYPE DECLARATIONS FOR MESSAGE BODY DEFINITIONS -->
			«FOR dataResource : resourceAPI.ownedResourceDefinitions SEPARATOR ""»
				«FOR method : dataResource.methods SEPARATOR ""»
					«method.request.generateMessageDataType»
					«FOR response : method.responses SEPARATOR ""»
						«response.generateMessageDataType»
					«ENDFOR»
				«ENDFOR»
			«ENDFOR»
			«FOR dataType : resourceAPI.zenModel.dataModels.map[it.ownedDataTypes].flatten SEPARATOR ""»
				«IF dataType instanceof Structure»
					«(dataType as Structure).generateInterfaceDataType(resourceAPI)»
				«ENDIF»
			«ENDFOR»
			</xs:schema>
		'''
	}

	def private Iterable<ReferenceProperty> getPathTo(ReferenceEmbed referenceEmbed) {
		var Collection<ReferenceProperty> containers = new LinkedList<ReferenceProperty>
		var Collection<ReferenceProperty> references = new LinkedList<ReferenceProperty>

		references = referenceEmbed.getContainmentReferences.putAll(ReferenceProperty)
		if (referenceEmbed.eContainer instanceof ReferenceEmbed)
			containers = getPathTo(referenceEmbed.eContainer as ReferenceEmbed).putAll(ReferenceProperty)
		references.add(referenceEmbed.referencePath.referenceSegment.referenceElement as ReferenceProperty)
		Iterables.concat(containers, references)
	}

	def private <T> T getBase(PropertyRealization property, Class<T> _class) {
		property.baseProperty as T
	}

	def private getMessageTypeName(TypedMessage message) {
		CommonServices.getMessageTypeName(message)
	}

	def private generateServiceDataResource(ServiceDataResource dataResource, ResourceAPI resourceAPI) {
		context.addTraceItem('complexType') //
		.withProperty('complexType', dataResource.complexTypeName) //
		.withProperty('elementName', dataResource.xsdElementName) //
		.withProperty('namespace', resourceAPI.namespace) //
		.withProperty('namespacePrefix', resourceAPI.nsPrefix) //
		.withPrimarySourceItem(locator.locate(resourceAPI)) //
		.withPrimarySourceItem(locator.locate(dataResource))
		'''
			«dataResource.type.generateComplexType(dataResource, resourceAPI)»
			«dataResource.generateElement»
			«dataResource.generateTransitionalContainersForReferenceLinks(resourceAPI)»
			«generateContainersForReferenceEmbeds(dataResource.name, dataResource, dataResource.referenceTreatments.toSet,
				resourceAPI)»
		'''
	}

	def private generateMessageDataType(TypedMessage message) {
		if (message != null) {
			if (message.actualType != null) {
				val method = message.getEContainer(Method)
				val resourceAPI = method.containingResourceDefinition.eContainer as ResourceAPI
				'''
					«message.getActualType.generateMessageComplexType(message, resourceAPI)»
					«message.generateMessageTypeElement»
					«message.generateTransitionalContainersForReferenceLinks(resourceAPI)»
					«generateContainersForReferenceEmbeds(message.messageTypeName, message, message.referenceTreatments,
						resourceAPI)»
				'''
			}
		}
	}

	def private generateMessageComplexType(Structure complexType, TypedMessage message, ResourceAPI resourceAPI) {
		'''
			<xs:complexType name="«message.messageTypeName»">
			«complexType.generateXSDDoc»
			«IF message.hasSequenceProperties»
				<xs:sequence>
				«FOR feature : message.getReferenceProperties SEPARATOR ""»
					«(feature as PropertyRealization).generateMessageTypeReferenceProperty(message, resourceAPI, new LinkedList())»
				«ENDFOR»
				«FOR feature : message.getPrimitiveMultiProperties SEPARATOR ""»
					«(feature as PropertyRealization).generatePrimitiveProperty(resourceAPI)»
				«ENDFOR»
				«FOR referenceLink : message.getReferenceLinks»
					«referenceLink.generateReferenceSegment(resourceAPI)»
				«ENDFOR»
				«FOR referenceEmbed : message.referenceTreatments.filter(ReferenceEmbed)»
					«generateNestedReference(referenceEmbed.referencePath.referenceSegment.referenceElement,
				complexTypeName(message.messageTypeName, referenceEmbed.referencePath.referenceSegment.referenceElement))»
				«ENDFOR»
				</xs:sequence>
			«ENDIF»
			«FOR feature : message.getIncludedProperties.filter[it.baseProperty.isPrimitiveProperty].filter[
				!it.isMultiValued] SEPARATOR ""»
				«feature.generatePrimitiveProperty(resourceAPI)»
			«ENDFOR»
			</xs:complexType>
		'''
	}

	def private generateMessageTypeElement(TypedMessage message) {
		'''
			<xs:element name="«message.messageTypeName.toFirstLower»" type="«message.messageTypeName»" />
		'''
	}

	def private generateMessageTypeReferenceProperty(PropertyRealization referenceProperty, TypedMessage message,
		ResourceAPI resourceAPI, Iterable<ReferenceProperty> pathToCurrentSegment) {
		if ((referenceProperty.baseProperty as ReferenceProperty).
			isPropertyOverridenByReferenceLink(message, pathToCurrentSegment)) {
			var LinkedList<ReferenceProperty> list
			list.add(referenceProperty.baseProperty as ReferenceProperty)
			generateContainmentProperty(
				referenceProperty,
				message.messageTypeName.complexTypeName(
					Iterables.concat(pathToCurrentSegment, list)
				)
			)

		}
	}

	def private generateComplexType(Structure complexType, ServiceDataResource dataResource, ResourceAPI resourceAPI) {
		'''
			<xs:complexType name="«dataResource.complexTypeName»">
			«complexType.generateXSDDoc»
			«IF dataResource instanceof CollectionResource»
				<xs:sequence>
				«FOR referenceLink : dataResource.getReferenceLinks SEPARATOR ""»
					«referenceLink.generateReferenceSegment(resourceAPI)»
				«ENDFOR»
				«FOR referenceEmbed : dataResource.referenceTreatments.filter(ReferenceEmbed) SEPARATOR ""»
					«referenceEmbed.referencePath.referenceSegment.referenceElement.generateNestedReference(
				complexTypeName(dataResource.name, referenceEmbed.referencePath.referenceSegment.referenceElement))»
				«ENDFOR»
				</xs:sequence>
			«ELSE»
				«IF dataResource.hasSequenceProperties»
					<xs:sequence>
					«FOR feature : dataResource.getReferenceProperties SEPARATOR ""»
						«feature.generateReferenceProperty(dataResource, resourceAPI, #[])»
					«ENDFOR»
					«FOR feature : dataResource.getPrimitiveMultiProperties SEPARATOR ""»
						«feature.generatePrimitiveProperty(resourceAPI)»
					«ENDFOR»
					«FOR referenceLink : dataResource.getReferenceLinks SEPARATOR ""»
						«referenceLink.generateReferenceSegment(resourceAPI)»
					«ENDFOR»
					«FOR referenceEmbed : dataResource.referenceTreatments.filter(ReferenceEmbed) SEPARATOR ""»
						«referenceEmbed.referencePath.referenceSegment.referenceElement.generateNestedReference(
				complexTypeName(dataResource.name, referenceEmbed.referencePath.referenceSegment.referenceElement))»
					«ENDFOR»
					</xs:sequence>
				«ENDIF»
				«FOR feature : dataResource.getIncludedProperties.filter[it.baseProperty.isPrimitiveProperty].filter[
				!it.isMultiValued] SEPARATOR ""»
					«feature.generatePrimitiveProperty(resourceAPI)»
				«ENDFOR»
			«ENDIF»
			</xs:complexType>
		'''
	}

	def private generateReferenceSegment(ReferenceLink referenceLink, ResourceAPI resourceAPI) {
		val ReferenceElement referenceProperty = referenceLink.getReferenceProperty
		val LinkDescriptor linkDescriptor = referenceLink.getLinkDescriptor

		'''
			«IF referenceProperty.isMultiValued»
				<xs:element name="«referenceProperty.getReferenceListElementName»" minOccurs="«referenceProperty.getListMinOccurs»" maxOccurs="1">
					<xs:complexType>
						<xs:sequence>
							<xs:element name="«referenceProperty.getReferenceElementName»" minOccurs="«referenceProperty.minOccurs»" maxOccurs="«referenceProperty.
				getListItemMaxOccurs»">
								<xs:complexType>
									<xs:sequence>
										«referenceLink.generateAtomLink»
										«IF linkDescriptor != null»
											«FOR feature : linkDescriptor.includedFeatures.getPrimitiveMultiProperties»
												«feature.generatePrimitiveProperty(resourceAPI)»
											«ENDFOR»
										«ENDIF»
									</xs:sequence>
									«IF linkDescriptor != null»
										«FOR feature : linkDescriptor.includedFeatures.getPrimitiveSimpleProperties»
											«feature.generatePrimitiveProperty(resourceAPI)»
										«ENDFOR»
									«ENDIF»
								</xs:complexType>
							</xs:element>
						</xs:sequence>
					</xs:complexType>
				</xs:element>
			«ELSE»
				<xs:element name="«referenceProperty.getReferenceElementName»" minOccurs="«referenceProperty.minOccurs»" maxOccurs="«referenceProperty.
				maxOccurs»">
					<xs:complexType>
						<xs:sequence>
							«referenceLink.generateAtomLink»
							«IF linkDescriptor != null»
								«FOR feature : linkDescriptor.includedFeatures.getPrimitiveMultiProperties»
									«feature.generatePrimitiveProperty(resourceAPI)»
								«ENDFOR»
							«ENDIF»
						</xs:sequence>
						«IF linkDescriptor != null»
							«FOR feature : linkDescriptor.includedFeatures.getPrimitiveSimpleProperties»
								«feature.generatePrimitiveProperty(resourceAPI)»
							«ENDFOR»
						«ENDIF»
					</xs:complexType>
				</xs:element>
			«ENDIF»
		'''
	}

	def private generateNestedReference(ReferenceElement referenceElement, String typeName) {
		if (!referenceElement.isMultiValued)
			referenceElement.generateSimpleNestedReference(typeName)
		else
			referenceElement.generateMultiNestedReference(typeName)
	}

	def private generateSimpleNestedReference(ReferenceElement referenceElement, String typeName) {
		'''
			<xs:element name="«referenceElement.referenceElementName»" type="«typeName»" minOccurs="«referenceElement.minOccurs»" maxOccurs="«referenceElement.
				maxOccurs»" />
		'''
	}

	def private generateMultiNestedReference(ReferenceElement referenceElement, String typeName) {
		'''
			<xs:element name="«referenceElement.referenceListElementName»" minOccurs="«referenceElement.listMinOccurs»" maxOccurs="1">
				<xs:complexType>
					<xs:sequence>
						<xs:element name="«referenceElement.referenceItemName»" type="«typeName»" minOccurs="«referenceElement.
				listItemMinOccurs»" maxOccurs="«referenceElement.listItemMaxOccurs»" />
					</xs:sequence>
				</xs:complexType>
			</xs:element>
		'''
	}

	def private dispatch generateElement(ServiceDataResource dataResource) {
		'''
			<xs:element name="«dataResource.xsdElementName»" type="«dataResource.complexTypeName»" />
		'''
	}

	def private dispatch generateElement(Structure complexType) {
		'''
			<xs:element name="«complexType.xsdElementName»" type="«complexType.complexTypeName»" />
		'''
	}

	def private generateTransitionalContainersForReferenceLinks(ServiceDataResource dataResource,
		ResourceAPI resourceAPI) {
		'''
			«FOR referenceProperty : getContainmentReferencesAtPosition(
				dataResource.getReferenceLinks.map[it as ReferenceTreatment], 1)»
				«generateContainmentSegment(referenceProperty, dataResource, resourceAPI)»
			«ENDFOR»
		'''
	}

	def private generateTransitionalContainersForReferenceLinks(TypedMessage message, ResourceAPI resourceAPI) {
		'''
			«FOR referenceProperty : getContainmentReferencesAtPosition(
				message.getReferenceLinks.map[it as ReferenceTreatment], 1)»
				«generateContainmentSegment(referenceProperty, message, resourceAPI)»
			«ENDFOR»
		'''
	}

	def private generateContainmentSegment(ReferenceProperty referenceProperty, ServiceDataResource dataResource,
		ResourceAPI resourceAPI) {
		var LinkedList<ReferenceProperty> path
		path.add(referenceProperty)
		generateContainmentSegment(path, dataResource, resourceAPI)
	}

	def private generateContainmentSegment(ReferenceProperty referenceProperty, TypedMessage message,
		ResourceAPI resourceAPI) {
		var LinkedList<ReferenceProperty> path
		path.add(referenceProperty)
		generateContainmentSegment(path, message, resourceAPI)
	}

	def private String generateContainmentSegment(Iterable<ReferenceProperty> pathToCurrentSegment,
		ServiceDataResource dataResource, ResourceAPI resourceAPI) {
		val currentType = pathToCurrentSegment.findLast[].type
		val levelOfContainment = pathToCurrentSegment.length

		'''
			<xs:complexType name=" «complexTypeName(dataResource.name, pathToCurrentSegment)»">
			«IF currentType.ownedFeatures.hasSequenceProperties»
				<xs:sequence>
				«FOR referenceProperty : currentType.ownedFeatures.getReferenceProperties»
					«referenceProperty.generateReferenceProperty(dataResource, resourceAPI, pathToCurrentSegment)»
				«ENDFOR»
				«FOR feature : currentType.ownedFeatures.getPrimitiveMultiProperties»
					«feature.generatePrimitiveProperty(resourceAPI)»
				«ENDFOR»
				«FOR referenceLink : dataResource.getReferenceLinks.filter[it.startsWithPath(pathToCurrentSegment)].filter[
				it.getContainmentDepth < levelOfContainment + 1]»
					«referenceLink.generateReferenceSegment(resourceAPI)»
				«ENDFOR»
				</xs:sequence>
			«ENDIF»
			«FOR feature : currentType.ownedFeatures.getPrimitiveProperties.filter[!isMultiValued(it)]»
				«feature.generatePrimitiveProperty(resourceAPI)»
			«ENDFOR»
			</xs:complexType>
			«FOR referenceProperty : getContainmentReferencesAtPosition(
				dataResource.getReferenceLinks.map[it as ReferenceTreatment], levelOfContainment + 1)»
				«var LinkedList<ReferenceProperty> path = pathToCurrentSegment as LinkedList<ReferenceProperty>»
				«path.add(referenceProperty)»
				«generateContainmentSegment(path, dataResource, resourceAPI)»
			«ENDFOR»
		'''
	}

	def private String generateContainmentSegment(Iterable<ReferenceProperty> pathToCurrentSegment,
		TypedMessage message, ResourceAPI resourceAPI) {
		val currentType = pathToCurrentSegment.findLast[].type;
		val levelOfContainment = pathToCurrentSegment.length
		'''
			<xs:complexType name="«complexTypeName(message.getMessageTypeName, pathToCurrentSegment)»">
			«IF currentType.ownedFeatures.hasSequenceProperties»
				<xs:sequence>
				«FOR referenceProperty : currentType.ownedFeatures.getReferenceProperties»
					«referenceProperty.generateReferenceProperty(message, resourceAPI, pathToCurrentSegment)»
				«ENDFOR»
				«FOR feature : currentType.ownedFeatures.getPrimitiveMultiProperties»
					«feature.generatePrimitiveProperty(resourceAPI)»
				«ENDFOR»
				«FOR referenceLink : message.getReferenceLinks.filter[startsWithPath(it, pathToCurrentSegment)].filter[
				it.getContainmentDepth < levelOfContainment + 1]»
					«referenceLink.generateReferenceSegment(resourceAPI)»
				«ENDFOR»
				</xs:sequence>
			«ENDIF»
			«FOR feature : currentType.ownedFeatures.getPrimitiveProperties.filter[!isMultiValued(it)]»
				«feature.generatePrimitiveProperty(resourceAPI)»
			«ENDFOR»
			</xs:complexType>
			«FOR referenceProperty : getContainmentReferencesAtPosition(
				message.getReferenceLinks.map[it as ReferenceTreatment], levelOfContainment + 1)»
				«var LinkedList<ReferenceProperty> path = pathToCurrentSegment as LinkedList<ReferenceProperty>»
				«path.add(referenceProperty)»
				«generateContainmentSegment(path, message, resourceAPI)»
			«ENDFOR»
		'''
	}

	def private String generateSchemaImports(ResourceAPI resourceAPI) {
		resourceAPI.generateAtomImports
	}

	def private String generateAtomImports(ResourceAPI resourceAPI) {
		'''
			<xs:import namespace="http://www.w3.org/2005/Atom" schemaLocation="atom.xsd" />
		'''
	}

	def private generateNamespaceAdditions(ResourceAPI resourceAPI) {
		'xmlns:atom="http://www.w3.org/2005/Atom"'
	}

	def private generateAtomLink(ReferenceLink referenceLink) {
		if (referenceLink.targetResource != null) '''
			<!-- A reference link to the «referenceLink.targetResource.name»-->
			<!--Recommended value of the 'rel' attribute is '«referenceLink.relValue»'-->
			<xs:element ref="atom:link" minOccurs="1" maxOccurs="1" />
		'''
	}

	def private dispatch generatePrimitiveProperty(PrimitiveProperty primitiveProperty, ResourceAPI resourceAPI) {
		if (!primitiveProperty.isMultiValued) {
			'''
				<xs:attribute name="«primitiveProperty.name.toFirstLower»" 
					type="«getTypeName(primitiveProperty, resourceAPI)»"
					use="optional" />
			'''
		} else '''
			<xs:element name="«primitiveProperty.name.toFirstLower»List" minOccurs="«primitiveProperty.listMinOccurs»" maxOccurs="1">
				<xs:complexType>
					<xs:sequence>
						<xs:element name="«primitiveProperty.propertyItemName»" type="«getTypeName(primitiveProperty, resourceAPI)»" minOccurs="«primitiveProperty.
				listItemMinOccurs»" maxOccurs="«primitiveProperty.getListItemMaxOccurs»" />
					</xs:sequence>
				</xs:complexType>
			</xs:element>
		'''
	}

	def private dispatch generatePrimitiveProperty(PropertyRealization primitiveProperty, ResourceAPI resourceAPI) {
		if (!primitiveProperty.isMultiValued) {
			'''
				<xs:attribute name="«primitiveProperty.baseProperty.name.toFirstLower»"
					«IF primitiveProperty.constraints.nullOrEmpty»
						type="«primitiveProperty.getBase(PrimitiveProperty).getTypeName(resourceAPI)»"
					«ENDIF»
					use="«primitiveProperty.use»"«IF primitiveProperty.constraints.nullOrEmpty»/«ENDIF»>
					«IF !primitiveProperty.constraints.nullOrEmpty»
						<xs:simpleType>
							«primitiveProperty.getBase(PrimitiveProperty).getTypeName(resourceAPI).generateRestriction(
					primitiveProperty.constraints)»
						</xs:simpleType>
						</xs:attribute>
					«ENDIF»
			'''
		} else {
			'''
				<xs:element name="«primitiveProperty.baseProperty.name.toFirstLower»List" minOccurs="«primitiveProperty.
					listMinOccurs»" maxOccurs="1">
					<xs:complexType>
						<xs:sequence>
							<xs:element name="«primitiveProperty.getBase(PrimitiveProperty).propertyItemName»" 
								type="«primitiveProperty.getBase(PrimitiveProperty).getTypeName(resourceAPI)»" minOccurs="«primitiveProperty.
					listItemMinOccurs»" maxOccurs="«primitiveProperty.listItemMaxOccurs»" />
						</xs:sequence>
					</xs:complexType>
				</xs:element>
			'''
		}
	}

	def private dispatch generateReferenceProperty(PropertyRealization referenceProperty, ServiceDataResource dataResource,
		ResourceAPI resourceAPI, Iterable<ReferenceProperty> pathToCurrentSegment) {
		if (referenceProperty.getBase(ReferenceProperty).
			isPropertyOverridenByReferenceLink(dataResource, pathToCurrentSegment)) {
			var LinkedList<ReferenceProperty> path
			path.add(referenceProperty.getBase(ReferenceProperty))
			referenceProperty.generateContainmentProperty(dataResource.name.complexTypeName(path))
		}
	}

	def private dispatch generateReferenceProperty(ReferenceProperty referenceProperty, ServiceDataResource dataResource,
		ResourceAPI resourceAPI, Iterable<ReferenceProperty> pathToCurrentSegment) {
		if (isPropertyOverridenByReferenceLink(referenceProperty, dataResource, pathToCurrentSegment)) {
			var LinkedList<ReferenceProperty> path = pathToCurrentSegment as LinkedList<ReferenceProperty>
			path.add(referenceProperty)
			referenceProperty.generateNestedReference(complexTypeName(dataResource.name, path))
		}
	}

	def private dispatch generateReferenceProperty(ReferenceProperty referenceProperty, TypedMessage message,
		ResourceAPI resourceAPI, Iterable<ReferenceProperty> pathToCurrentSegment) {
		if (isPropertyOverridenByReferenceLink(referenceProperty, message, pathToCurrentSegment)) {
			var LinkedList<ReferenceProperty> path = pathToCurrentSegment as LinkedList<ReferenceProperty>
			path.add(referenceProperty)
			referenceProperty.generateNestedReference(complexTypeName(message.messageTypeName, path))
		}
	}

	def private generateContainmentProperty(PropertyRealization property, String nameOfCorrespondingComplexType) {
		if (!property.isMultiValued)
			property.generateSimpleContainmentProperty(nameOfCorrespondingComplexType)
		else
			property.generateMultiContainmentProperty(nameOfCorrespondingComplexType)
	}

	def private generateSimpleContainmentProperty(PropertyRealization property, String nameOfCorrespondingComplexType) {
		'''
			<xs:element name="«property.getBase(ReferenceProperty).referenceElementName»" type="«nameOfCorrespondingComplexType»" minOccurs="«property.
				minOccurs»" maxOccurs="«property.maxOccurs»" />
		'''
	}

	def private generateMultiContainmentProperty(PropertyRealization property, String nameOfCorrespondingComplexType) {
		'''
			<xs:element name="«property.getBase(ReferenceProperty).referenceListElementName»" minOccurs="«property.listMinOccurs»" maxOccurs="1">
				<xs:complexType>
					<xs:sequence>
						<xs:element name="«property.getBase(ReferenceProperty).getReferenceItemName»" type="«nameOfCorrespondingComplexType»" minOccurs="«property.
				listItemMinOccurs»" maxOccurs="«property.listItemMaxOccurs»" />
					</xs:sequence>
				</xs:complexType>
			</xs:element>
		'''
	}

	def private getUse(PropertyRealization property) {
		if(property.isRequired) 'required' else 'optional'
	}

	def private generateInterfaceDataType(Structure complexType, ResourceAPI resourceAPI) {
		if(resourceAPI.getDefaultResource(complexType, true) == null) complexType.generateComplexType(resourceAPI)
	}

	def private generateComplexType(Structure complexType, ResourceAPI resourceAPI) {
		val features = complexType.ownedFeatures
		'''
			<xs:complexType name="«complexType.complexTypeName»">
			«complexType.generateXSDDoc»
			«IF features.hasSequenceProperties»
				<xs:sequence>
				«FOR feature : features.getPrimitiveMultiProperties SEPARATOR ""»
					«feature.generatePrimitiveProperty(resourceAPI)»
				«ENDFOR»
				</xs:sequence>
			«ENDIF»
			«FOR feature : features.getPrimitiveProperties.filter[!it.isMultiValued] SEPARATOR ""»
				«feature.generatePrimitiveProperty(resourceAPI)»
			«ENDFOR»
			</xs:complexType>
		'''
	}

	def private generateContainersForReferenceEmbeds(String name, EObject obj,
		Iterable<ReferenceTreatment> referenceTreatments, ResourceAPI resourceAPI) {

		'''
			«FOR referenceEmbed : referenceTreatments.filter(ReferenceEmbed)»
				«referenceEmbed.generateContainersForReferenceEmbed(name, obj, resourceAPI)»
			«ENDFOR»
		'''
	}

	def private String generateContainersForReferenceEmbed(ReferenceEmbed referenceEmbed, String name, EObject obj,
		ResourceAPI resourceAPI) {
		val pathToReferenceEmbed = getPathTo(referenceEmbed)
		'''
			«pathToReferenceEmbed.generateEmbedSegment(name, obj, referenceEmbed)»
			«FOR childReferenceEmbed : referenceEmbed.nestedReferenceTreatments.filter(ReferenceEmbed)»
				«childReferenceEmbed.generateContainersForReferenceEmbed(name, obj, resourceAPI)»
			«ENDFOR»
		'''
	}

	def private generateEmbedSegment(Iterable<ReferenceProperty> pathToCurrentSegment, String name, EObject obj,
		ReferenceEmbed referenceEmbed) {
		'''
			<xs:complexType name="«complexTypeName(name, pathToCurrentSegment)»">
			«IF referenceEmbed.linkDescriptor != null»
				<xs:sequence>
				«FOR feature : getPrimitiveProperties(referenceEmbed.linkDescriptor.includedFeatures).filter[it.isMultiValued]»
					«feature.generatePrimitiveProperty(obj.getEContainer(ResourceAPI))»
				«ENDFOR»
				«FOR referenceLink : referenceEmbed.nestedReferenceTreatments.filter(ReferenceLink)»
					«referenceLink.generateReferenceSegment(obj.getEContainer(ResourceAPI))»
				«ENDFOR»
				«FOR refEmbed : referenceEmbed.nestedReferenceTreatments.filter[it instanceof ReferenceEmbed]»
					«var Iterable<ReferenceProperty> path = Iterables::concat(pathToCurrentSegment.putAll(ReferenceProperty),
				#[refEmbed.referencePath.referenceSegment.referenceElement as ReferenceProperty])»
					«generateNestedReference(refEmbed.referencePath.referenceSegment.referenceElement, complexTypeName(name, path))»
				«ENDFOR»
				</xs:sequence>
				«FOR feature : getPrimitiveProperties(referenceEmbed.linkDescriptor.includedFeatures).filter[!isMultiValued(it)]»
					«feature.generatePrimitiveProperty(obj.getEContainer(ResourceAPI))»
				«ENDFOR»
			«ENDIF»
			</xs:complexType>
		'''
	}
}