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
import com.modelsolv.reprezen.gentemplates.common.services.CommonServices
import com.modelsolv.reprezen.restapi.PrimitiveTypeSourceReference
import com.modelsolv.reprezen.restapi.PropertyRealization
import com.modelsolv.reprezen.restapi.PropertyReference
import com.modelsolv.reprezen.restapi.ReferenceLink
import com.modelsolv.reprezen.restapi.ResourceAPI
import com.modelsolv.reprezen.restapi.ServiceDataResource
import com.modelsolv.reprezen.restapi.SourceReference
import com.modelsolv.reprezen.restapi.TypedMessage
import com.modelsolv.reprezen.restapi.datatypes.DataModel
import com.modelsolv.reprezen.restapi.datatypes.Feature
import com.modelsolv.reprezen.restapi.datatypes.PrimitiveProperty
import com.modelsolv.reprezen.restapi.datatypes.PrimitiveType
import com.modelsolv.reprezen.restapi.datatypes.ReferenceElement
import com.modelsolv.reprezen.restapi.datatypes.ReferenceProperty
import com.modelsolv.reprezen.restapi.datatypes.Structure

class FeatureHelper {
	extension XMLSchemaHelper = new XMLSchemaHelper
	val static UNBOUNDED = 'unbounded'
	val commonServices = new CommonServices

	def dispatch isRequired(Feature feature) {
		feature.minOccurs > 0
	}

	def dispatch isRequired(ReferenceElement feature) {
		feature.minOccurs > 0
	}

	def dispatch isRequired(PropertyRealization includedProperty) {
		includedProperty.minOccurs > 0
	}

	def getReferenceItemName(ReferenceElement referenceElement) {
		// referenceElement.dataType.name.toFirstLower
		referenceElement.name.toFirstLower
	}

	def getReferenceElementName(ReferenceElement referenceElement) {
		referenceElement.name.toFirstLower
	}

	def getReferenceListElementName(ReferenceElement referenceElement) {
		getReferenceElementName(referenceElement) + "List"
	}

	def getTypeName(PrimitiveProperty primitiveProperty, ResourceAPI resourceAPI) {
		val prefix = if (primitiveProperty.type instanceof PrimitiveType)
				"xs"
			else {
				primitiveProperty.type.getEContainer(DataModel).nsPrefix(resourceAPI)
			}
		return prefix + ":" + primitiveProperty.primitiveFeatureType
	}

	def getPropertyItemName(PrimitiveProperty property) {
		'item'
	}

	def ReferenceLink getReferenceLink(Feature feature, Iterable<ReferenceLink> referenceLinks) {
		var refs = referenceLinks.filter[referenceElement == feature]
		if(refs.nullOrEmpty) null else refs.findFirst[]
	}

	def dispatch getListMinOccurs(Feature feature) {
		if(feature.isRequired) 1 else 0
	}

	def dispatch getListMinOccurs(ReferenceElement feature) {
		if(feature.isRequired) 1 else 0
	}

	def dispatch getListMinOccurs(PropertyRealization feature) {
		if(feature.isRequired) 1 else 0
	}

	def dispatch getListItemMinOccurs(Feature feature) {
		if(feature.minOccurs >= 1) feature.minOccurs else 0
	}

	def dispatch getListItemMinOccurs(ReferenceElement feature) {
		if(feature.minOccurs >= 1) feature.minOccurs else 0
	}

	def dispatch getListItemMinOccurs(PropertyRealization feature) {
		if(feature.minOccurs >= 1) feature.minOccurs else 0
	}

	def dispatch getListItemMaxOccurs(Feature feature) {
		if(feature.maxOccurs != -1) feature.maxOccurs.normalizedMaxOccurs else UNBOUNDED
	}

	def dispatch getListItemMaxOccurs(ReferenceElement feature) {
		if(feature.maxOccurs != -1) feature.maxOccurs.normalizedMaxOccurs else UNBOUNDED
	}

	def dispatch getListItemMaxOccurs(PropertyRealization feature) {
		if(feature.maxOccurs != -1) feature.maxOccurs.normalizedMaxOccurs else UNBOUNDED
	}

	def dispatch Iterable<Feature> getSequenceProperties(Structure dataType) {
		dataType.ownedFeatures.sequenceProperties.map[it as Feature]
	}

	def dispatch Iterable<PropertyRealization> getSequenceProperties(ServiceDataResource dataResource) {
		Iterables.concat(dataResource.dataType.ownedFeatures.referenceProperties.map[it as PropertyRealization],
			dataResource.primitiveMultiProperties.map[it as PropertyRealization])
	}

	def dispatch Iterable<PropertyRealization> getSequenceProperties(TypedMessage message) {
		Iterables.concat(message.actualType.ownedFeatures.referenceProperties.map[it as PropertyRealization],
			message.primitiveMultiProperties.map[it as PropertyRealization])
	}

	def dispatch Iterable<Feature> getSequenceProperties(Iterable<Feature> features) {
		Iterables.concat(features.referenceProperties.map[it as Feature],
			features.primitiveMultiProperties.map[it as Feature])
	}

	def Iterable<PrimitiveProperty> getPrimitiveProperties(Iterable<Feature> features) {
		features.filter[it.isPrimitiveProperty].map[it as PrimitiveProperty]
	}

	def dispatch Iterable<ReferenceProperty> getReferenceProperties(Iterable<Feature> features) {
		features.filter[it instanceof ReferenceProperty].map[it as ReferenceProperty]
	}

	def dispatch Iterable<PropertyRealization> getReferenceProperties(ServiceDataResource dataResource) {
		dataResource.includedProperties.filter[isReferenceProperty(it.baseProperty)]
	}

	def dispatch Iterable<PropertyRealization> getReferenceProperties(TypedMessage message) {
		message.includedProperties.filter[isReferenceProperty(it.baseProperty)]
	}

	def isPrimitiveProperty(Feature feature) {
		feature instanceof PrimitiveProperty
	}

	def dispatch Iterable<PrimitiveProperty> getPrimitiveMultiProperties(Iterable<Feature> features) {
		features.filter[it.isMultiValued].primitiveProperties
	}

	def dispatch Iterable<PropertyRealization> getPrimitiveMultiProperties(ServiceDataResource dataResource) {
		dataResource.includedProperties.filter[isPrimitiveProperty(it.baseProperty) && it.isMultiValued]
	}

	def dispatch Iterable<PropertyRealization> getPrimitiveMultiProperties(TypedMessage message) {
		message.includedProperties.filter[isPrimitiveProperty(it.baseProperty) && it.isMultiValued]
	}

	def Iterable<PrimitiveProperty> getPrimitiveSimpleProperties(Iterable<Feature> features) {
		features.primitiveProperties.filter[!it.isMultiValued]
	}

	def dispatch hasSequenceProperties(Iterable<Feature> features) {
		!features.sequenceProperties.nullOrEmpty
	}

	def dispatch hasSequenceProperties(ServiceDataResource dataResource) {
		!dataResource.sequenceProperties.nullOrEmpty
	}

	def dispatch hasSequenceProperties(TypedMessage message) {
		!message.sequenceProperties.nullOrEmpty
	}

	def dispatch isMultiValued(Feature feature) {
		(feature.maxOccurs > 1) || (feature.maxOccurs == -1)
	}

	def dispatch isMultiValued(ReferenceElement feature) {
		(feature.maxOccurs > 1) || (feature.maxOccurs == -1)
	}

	def dispatch isMultiValued(PropertyRealization feature) {
		(feature.maxOccurs > 1) || (feature.maxOccurs == -1)
	}

	def isPrimitivePropertyReference(PropertyReference featureReference) {
		featureReference.conceptualFeature.isPrimitiveProperty
	}

	def isPrimitiveSourceReference(SourceReference sourceReference) {
		if (sourceReference instanceof PropertyReference)
			(sourceReference as PropertyReference).isPrimitivePropertyReference
		else
			sourceReference instanceof PrimitiveTypeSourceReference
	}

	def isReferencePropertyReference(PropertyReference featureReference) {
		featureReference.conceptualFeature.isReferenceProperty
	}

	def isReferenceProperty(Feature feature) {
		feature instanceof ReferenceProperty
	}

	def isReferenceSourceReference(SourceReference sourceReference) {
		if (sourceReference instanceof PropertyReference)
			(sourceReference as PropertyReference).isReferencePropertyReference
		else
			false
	}

	def public normalizedMaxOccurs(Integer value) {
		if(value == 0) 1 else value
	}

	def primitiveFeatureType(PrimitiveProperty primitiveProperty) {
		primitiveProperty.type.name
	}

	def referenceFeatureType(ReferenceProperty referenceProperty) {
		referenceProperty.type.name
	}

	def featureType(Feature feature) {
		if (feature.isPrimitiveProperty)
			(feature as PrimitiveProperty).primitiveFeatureType
		else
			(feature as ReferenceProperty).referenceFeatureType
	}

	def getPrettyPrintedMultiplicity(Feature feature) {
		commonServices.getPrettyPrintedMultiplicity(feature)
	}

	def getPrettyPrintedCardinality(PropertyRealization includedProperty) {
		commonServices.getPrettyPrintedCardinality(includedProperty)
	}
}
