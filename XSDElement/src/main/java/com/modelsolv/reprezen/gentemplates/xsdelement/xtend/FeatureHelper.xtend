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
import com.modelsolv.reprezen.restapi.PropertyRealization
import com.modelsolv.reprezen.restapi.ReferenceLink
import com.modelsolv.reprezen.restapi.ResourceAPI
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

	def dispatch boolean isRequired(Feature feature) {
		feature.minOccurs > 0
	}

	def dispatch boolean isRequired(ReferenceElement feature) {
		feature.minOccurs > 0
	}

	def dispatch boolean isRequired(PropertyRealization includedProperty) {
		includedProperty.minOccurs > 0
	}

	def getReferenceItemName(ReferenceElement referenceElement) {
		referenceElement.dataType.name.toFirstLower
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
		var refs = referenceLinks.filter[it.referencePath.referenceSegment.referenceElement == feature]
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
		if(feature.minOccurs > 1) feature.minOccurs else 1
	}

	def dispatch getListItemMinOccurs(ReferenceElement feature) {
		if(feature.minOccurs > 1) feature.minOccurs else 1
	}

	def dispatch getListItemMinOccurs(PropertyRealization feature) {
		if(feature.minOccurs > 1) feature.minOccurs else 1
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

	def Iterable<PrimitiveProperty> getPrimitiveProperties(Iterable<Feature> features) {
		features.filter[it.isPrimitiveProperty].map[it as PrimitiveProperty]
	}

	def Iterable<ReferenceProperty> getReferenceProperties(Iterable<Feature> features) {
		features.filter[it instanceof ReferenceProperty].map[it as ReferenceProperty]
	}

	def isPrimitiveProperty(Feature feature) {
		feature instanceof PrimitiveProperty
	}

	def Iterable<PrimitiveProperty> getPrimitiveMultiProperties(Iterable<Feature> features) {
		features.filter[it.isMultiValued].primitiveProperties
	}

	def Iterable<PrimitiveProperty> getPrimitiveSingleProperties(Iterable<Feature> features) {
		features.primitiveProperties.filter[!it.isMultiValued]
	}

	def hasSequenceProperties(Iterable<Feature> features) {
		!features.sequenceProperties.nullOrEmpty
	}

	def private dispatch Iterable<Feature> getSequenceProperties(Structure dataType) {
		dataType.ownedFeatures.sequenceProperties.map[it as Feature]
	}

	def private dispatch Iterable<Feature> getSequenceProperties(Iterable<Feature> features) {
		Iterables.concat(features.referenceProperties.map[it as Feature],
			features.primitiveMultiProperties.map[it as Feature])
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

	def public normalizedMaxOccurs(Integer value) {
		if(value == 0) 1 else value
	}

	def private primitiveFeatureType(PrimitiveProperty primitiveProperty) {
		primitiveProperty.type.name
	}

}
