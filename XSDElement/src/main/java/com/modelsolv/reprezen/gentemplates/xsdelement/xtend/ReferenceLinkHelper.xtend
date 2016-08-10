/*******************************************************************************
 * Copyright © 2013, 2016 Modelsolv, Inc.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property
 * of ModelSolv, Inc. See the file license.html in the root directory of
 * this project for further information.
 *******************************************************************************/
package com.modelsolv.reprezen.gentemplates.xsdelement.xtend

import com.modelsolv.reprezen.restapi.datatypes.ReferenceProperty
import com.modelsolv.reprezen.restapi.ReferenceTreatment
import com.modelsolv.reprezen.restapi.ServiceDataResource
import com.modelsolv.reprezen.restapi.TypedMessage
import com.modelsolv.reprezen.restapi.ReferenceLink
import com.modelsolv.reprezen.restapi.ResourceDefinition
import com.modelsolv.reprezen.restapi.LinkDescriptor
import java.util.LinkedList
import com.modelsolv.reprezen.restapi.ContainmentPathSegment
import com.google.common.collect.Iterables
import com.modelsolv.reprezen.restapi.ReferenceEmbed

class ReferenceLinkHelper {
	extension XMLSchemaHelper = new XMLSchemaHelper

	def Iterable<ReferenceProperty> getContainmentReferencesAtPosition(Iterable<ReferenceTreatment> referenceTreatments,
		Integer index) {
		referenceTreatments.filter[it.containmentReferences.size >= index].map[
			it.containmentReferences.toList.get(index)].toSet
	}

	def dispatch isPropertyOverridenByReferenceLink(ReferenceProperty referenceProperty,
		ServiceDataResource dataResource, Iterable<ReferenceProperty> pathToCurrentSegment) {
		isPropertyOverridenByReferenceLink(
			referenceProperty,
			getContainmentReferencesAtPosition(
				dataResource.referenceLinks.map[it as ReferenceTreatment],
				pathToCurrentSegment.size + 1
			)
		)
	}

	def dispatch isPropertyOverridenByReferenceLink(ReferenceProperty referenceProperty, TypedMessage message,
		Iterable<ReferenceProperty> pathToCurrentSegment) {
		isPropertyOverridenByReferenceLink(
			referenceProperty,
			getContainmentReferencesAtPosition(
				message.referenceLinks.map[it as ReferenceTreatment],
				pathToCurrentSegment.size + 1
			)
		)
	}

	def private isPropertyOverridenByReferenceLink(ReferenceProperty referenceProperty,
		Iterable<ReferenceProperty> featuresOverridenByReferenceLinks) {
		featuresOverridenByReferenceLinks.exists[it == referenceProperty]
	}

	def dispatch LinkDescriptor getLinkDescriptor(ReferenceLink referenceLink) {
		if(referenceLink.linkDescriptor != null) referenceLink.linkDescriptor else referenceLink.targetResource.
			linkDescriptor
	}

	def dispatch LinkDescriptor getLinkDescriptor(ResourceDefinition dataResource) {
		if ((dataResource != null) && (dataResource instanceof ServiceDataResource))
			(dataResource as ServiceDataResource).defaultLinkDescriptor
		else
			null
	}

	def getReferenceTreatmentName(ReferenceTreatment referenceLink) {
		referenceLink.containmentReferences.map[it.name].join(".") + "." +
			referenceLink.referencePath.referenceSegment.referenceElement.name
	}

	def dispatch Iterable<ReferenceProperty> getContainmentReferences(ReferenceTreatment referenceLink) {
		new LinkedList<ReferenceProperty>
	}

	def dispatch Iterable<ReferenceProperty> getContainmentReferences(ContainmentPathSegment containmentSegment) {
		var LinkedList<ReferenceProperty> result = new LinkedList<ReferenceProperty>

		if (containmentSegment != null) {
			result.add(containmentSegment.referenceElement as ReferenceProperty)
			Iterables.concat(result, containmentSegment.nextSegment.containmentReferences)
		}
		result
	}

	def getReferenceProperty(ReferenceLink referenceLink) {
		referenceLink.referenceElement
	}

	def getRelValue(ReferenceLink referenceLink) {
		if(referenceLink.linkRelation == null) null else referenceLink.linkRelation.name
	}

	def ServiceDataResource getContainingServiceDataResource(ReferenceTreatment referenceLink) {
        val eServiceDataResource = referenceLink.getEContainer(ServiceDataResource)
        val eReferenceEmbed = referenceLink.getEContainer(ReferenceEmbed)
        
        if(eServiceDataResource != null) eServiceDataResource
        else eReferenceEmbed.containingServiceDataResource
	}

	def public startsWithPath(ReferenceTreatment referenceLink, Iterable<ReferenceProperty> containmentPath) {
		containmentPath == referenceLink.getFirstContainmentFragments(containmentPath.size)
	}

	def dispatch private Iterable<ReferenceProperty> getFirstContainmentFragments(ReferenceTreatment referenceTreatment,
		Integer number) {
		referenceTreatment.containmentReferences.getFirstContainmentFragments(number)
	}

	def dispatch private Iterable<ReferenceProperty> getFirstContainmentFragments(
		Iterable<ReferenceProperty> containmentPath, Integer number) {
		if(containmentPath.size >= number) containmentPath.take(number) else null
	}

	def public getContainmentDepth(ReferenceLink referenceLink) {
		0
	}
}
