package com.firstdraft.foundation

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.ListView
import com.firstdraft.foundation.generated.GeneratedApplication
import dev.hotwire.navigation.destinations.HotwireDestinationDeepLink
import dev.hotwire.navigation.fragments.HotwireFragment

@HotwireDestinationDeepLink(uri = "hotwire://fragment/firstdraft-more")
class MoreFragment : HotwireFragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, state: Bundle?): View =
        inflater.inflate(R.layout.fragment_more, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        labelNavigationButton()
        val entries = AppNavigation.overflowEntries(GeneratedApplication.entries)
        view.findViewById<ListView>(R.id.more_entries).apply {
            adapter = ArrayAdapter(requireContext(), android.R.layout.simple_list_item_1, entries.map { it.label })
            setOnItemClickListener { _, _, position, _ ->
                navigator.route(AppConfiguration.rootOrigin + entries[position].path)
            }
        }
    }
}
