package com.firstdraft.foundation.generated

import com.firstdraft.foundation.BuildConfig
import org.junit.Assert.assertEquals
import org.junit.Test

class GeneratedApplicationTest {
    @Test fun emittedIdentityAndNavigationMatchThePlan() {
        assertEquals("3096a118457dd09f41ecdd482cd5788152895aeeda77bd5f3d3914a958aa904b", GeneratedApplication.foundationPlanSha256)
        assertEquals(BuildConfig.FOUNDATION_PLAN_SHA256, GeneratedApplication.foundationPlanSha256)
        assertEquals("invalid.firstdraft.reading_list", BuildConfig.APPLICATION_ID)
        assertEquals("https://reading-list.invalid", GeneratedApplication.railsOrigin)
        assertEquals(listOf("entity-index:01a0d534-d39d-7392-a0d1-604fc1c20526"), GeneratedApplication.entries.map { it.id })
        assertEquals(listOf("/books"), GeneratedApplication.entries.map { it.path })
        assertEquals(1, GeneratedApplication.hostIds.size)
    }
}
