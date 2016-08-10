/*******************************************************************************
 * Copyright © 2013, 2016 Modelsolv, Inc.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property
 * of ModelSolv, Inc. See the file license.html in the root directory of
 * this project for further information.
 *******************************************************************************/
package com.modelsolv.reprezen.gentemplates.xsdelement;

import com.modelsolv.reprezen.core.xml.XmlFormatter;
import com.modelsolv.reprezen.generators.api.GenerationException;
import com.modelsolv.reprezen.generators.api.template.GenTemplate;
import com.modelsolv.reprezen.generators.api.zenmodel.ZenModelGenTemplate;
import com.modelsolv.reprezen.gentemplates.xsdelement.xtend.XGenerateDataModel;
import com.modelsolv.reprezen.gentemplates.xsdelement.xtend.XGenerateResourceAPI;
import com.modelsolv.reprezen.restapi.ZenModel;

/**
 * @author Konstantin Zaitsev
 * @date Jun 24, 2015
 */
public class XMLSchemaGenTemplate extends ZenModelGenTemplate {

    /** XML Formatter. */
    private final XmlFormatter formatter = new XmlFormatter();

    @Override
    public String getName() {
        return "XML Schema (Element)"; //$NON-NLS-1$
    }

    @Override
    public void configure() throws GenerationException {
        defineZenModelSource();
        define(outputItem().named("ResourceAPI").using(XGenerateResourceAPI.class)
                .writing("${org.eclipse.xtext.xbase.lib.StringExtensions.toFirstLower(resourceAPI.name)}.xsd"));
        define(outputItem().named("DataModel").using(XGenerateDataModel.class));
        define(staticResource().copying("resources").to("."));
    }

    @Override
    public Generator getGenerator() {
        return new Generator();
    }

    public class Generator extends GenTemplate<ZenModel>.Generator {
        @Override
        protected String postProcessContent(String content) throws Exception {
            return formatter.format(content);
        }
    }
}
