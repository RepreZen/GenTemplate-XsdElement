/*******************************************************************************
 * Copyright © 2013, 2016 Modelsolv, Inc.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property
 * of ModelSolv, Inc. See the file license.html in the root directory of
 * this project for further information.
 *******************************************************************************/
package com.modelsolv.reprezen.gentemplates.xsdelement.xtend

import com.modelsolv.reprezen.restapi.ObjectResource
import com.modelsolv.reprezen.restapi.ReferenceLink
import com.modelsolv.reprezen.restapi.ResourceAPI
import com.modelsolv.reprezen.restapi.ServiceDataResource
import com.modelsolv.reprezen.restapi.datatypes.ReferenceElement
import com.modelsolv.reprezen.restapi.datatypes.ReferenceProperty
import com.modelsolv.reprezen.restapi.datatypes.Structure

class ResourceHelper {
	extension XMLSchemaHelper = new XMLSchemaHelper
	extension FeatureHelper = new FeatureHelper

	def dispatch complexTypeName(String dataResourceName, ReferenceElement refElement) {
		dataResourceName + "_" + refElement.name
	}

	def dispatch complexTypeName(String dataResourceName, Iterable<ReferenceElement> refElements) {
		dataResourceName + "_" + refElements.map[it.name].join('_')
	}

	def ObjectResource getCorrespondingResource(Structure complexType, ResourceAPI resourceAPI) {
		val defaultResource = complexType.getDefaultResource(resourceAPI)
		if (defaultResource != null)
			defaultResource
		else {
			val onlyResource = complexType.getOnlyResource(resourceAPI)
			if(onlyResource != null) defaultResource else null
		}
	}

	def private ObjectResource getDefaultResource(Structure complexType, ResourceAPI resourceAPI) {
		val resources = complexType.getAllResources(resourceAPI).filter[it.^default]
		if(resources.nullOrEmpty) null else resources.findFirst[]
	}

	def private ServiceDataResource getOnlyResource(Structure complexType, ResourceAPI resourceAPI) {
		val resources = complexType.getAllResources(resourceAPI)
		if(resources.size == 1) resources.findFirst[] else null
	}

    def ServiceDataResource getTargetResource(ReferenceProperty feature, ServiceDataResource dataResource) {
        val referenceLink = feature.getReferenceLink(dataResource.referenceLinks as Iterable<ReferenceLink>)
        if(referenceLink != null) referenceLink.targetResource as ServiceDataResource else feature.type.
            getCorrespondingResource(dataResource.getInterface)
    }

	def private Iterable<ObjectResource> getAllResources(Structure complexType, ResourceAPI resourceAPI) {
		resourceAPI.ownedResourceDefinitions.map[it as ObjectResource].filter[it.type == complexType]
	}

	def ResourceAPI getInterface(ServiceDataResource dataResource) {
		if(dataResource == null) null else dataResource.getEContainer(ResourceAPI)
	}
}
