class Sidebar
	constructor: (wrapper_key) ->
		@ws = new ZeroWebsocket(wrapper_key)
		@ws.route = @route
		@update()

	route: (message) ->
		if message.cmd == "setSiteInfo"
			RateLimit 1500, =>
				@update()
			RateLimit 30000, =>
				@displayGlobe()

	update: ->
		tag = document.querySelector(".content")

		@ws.cmd "sidebarGetHtmlTag", [], (html) ->
			options = {}
			is_first_time = tag.children.length == 0
			if is_first_time
				# Ignore globe loaded state
				options.onBeforeMorphEl = (from_el, to_el) ->
					return (
						from_el.className != "globe" and
						not from_el.classList.contains("noupdate")
					)
			morphdom tag, html, options
			if is_first_time
				@setup()

	setup: ->
		# Re-calculate height when site admin opened or closed
		@onClick "#checkbox-owned", ( =>
			setTimeout ( =>
				@scrollable()
			), 300
		)

		# Site limit button
		@onClick "#button-sitelimit", ( =>
			@wrapper.ws.cmd "siteSetLimit", $("#input-sitelimit").val(), (res) =>
				if res == "ok"
					@wrapper.notifications.add "done-sitelimit", "done", "Site storage limit modified!", 5000
				@update()
			return false
		)

		# Site autodownload limit button
		@onClick "#button-autodownload_bigfile_size_limit", ( =>
			@wrapper.ws.cmd "siteSetAutodownloadBigfileLimit", $("#input-autodownload_bigfile_size_limit").val(), (res) =>
				if res == "ok"
					@wrapper.notifications.add "done-bigfilelimit", "done", "Site bigfile auto download limit modified!", 5000
				@update()
			return false
		)

		# Database reload
		@onClick "#button-dbreload", ( =>
			@wrapper.ws.cmd "dbReload", [], =>
				@wrapper.notifications.add "done-dbreload", "done", "Database schema reloaded!", 5000
				@update()
			return false
		)

		# Database rebuild
		@onClick "#button-dbrebuild", ( =>
			@wrapper.notifications.add "done-dbrebuild", "info", "Database rebuilding...."
			@wrapper.ws.cmd "dbRebuild", [], =>
				@wrapper.notifications.add "done-dbrebuild", "done", "Database rebuilt!", 5000
				@update()
			return false
		)

		# Update site
		@onClick "#button-update", ( =>
			@tag.find("#button-update").addClass("loading")
			@wrapper.ws.cmd "siteUpdate", @wrapper.site_info.address, =>
				@wrapper.notifications.add "done-updated", "done", "Site updated!", 5000
				@tag.find("#button-update").removeClass("loading")
			return false
		)

		# Pause site
		@onClick "#button-pause", ( =>
			@tag.find("#button-pause").addClass("hidden")
			@wrapper.ws.cmd "sitePause", @wrapper.site_info.address
			return false
		)

		# Resume site
		@onClick "#button-resume", ( =>
			@tag.find("#button-resume").addClass("hidden")
			@wrapper.ws.cmd "siteResume", @wrapper.site_info.address
			return false
		)

		# Delete site
		@onClick "#button-delete", ( =>
			@wrapper.displayConfirm "Are you sure?", ["Delete this site", "Blacklist"], (confirmed) =>
				if confirmed == 1
					@tag.find("#button-delete").addClass("loading")
					@wrapper.ws.cmd "siteDelete", @wrapper.site_info.address, ->
						document.location = $(".fixbutton-bg").attr("href")
				else if confirmed == 2
					@wrapper.displayPrompt "Blacklist this site", "text", "Delete and Blacklist", "Reason", (reason) =>
						@tag.find("#button-delete").addClass("loading")
						@wrapper.ws.cmd "siteblockAdd", [@wrapper.site_info.address, reason]
						@wrapper.ws.cmd "siteDelete", @wrapper.site_info.address, ->
							document.location = $(".fixbutton-bg").attr("href")
			return false
		)

		# Owned checkbox
		@tag.find("#checkbox-owned").on "click touchend", =>
			@wrapper.ws.cmd "siteSetOwned", [@tag.find("#checkbox-owned").is(":checked")]

		# Auto download checkbox
		@tag.find("#checkbox-autodownloadoptional").on "click touchend", =>
			@wrapper.ws.cmd "siteSetAutodownloadoptional", [@tag.find("#checkbox-autodownloadoptional").is(":checked")]

		# Change identity button
		@tag.find("#button-identity").on "click touchend", =>
			@wrapper.ws.cmd "certSelect"
			return false

		# Save settings
		@tag.find("#button-settings").on "click touchend", =>
			@wrapper.ws.cmd "fileGet", "content.json", (res) =>
				data = JSON.parse(res)
				data["title"] = $("#settings-title").val()
				data["description"] = $("#settings-description").val()
				json_raw = unescape(encodeURIComponent(JSON.stringify(data, undefined, '\t')))
				@wrapper.ws.cmd "fileWrite", ["content.json", btoa(json_raw), true], (res) =>
					if res != "ok" # fileWrite failed
						@wrapper.notifications.add "file-write", "error", "File write error: #{res}"
					else
						@wrapper.notifications.add "file-write", "done", "Site settings saved!", 5000
						if @wrapper.site_info.privatekey
							@wrapper.ws.cmd "siteSign", {privatekey: "stored", inner_path: "content.json", update_changed_files: true}
						@update()
			return false


		# Open site directory
		@tag.find("#link-directory").on "click touchend", =>
			@wrapper.ws.cmd "serverShowdirectory", ["site", @wrapper.site_info.address]
			return false

		# Copy site with peers
		@tag.find("#link-copypeers").on "click touchend", (e) =>
			copy_text = e.currentTarget.href
			handler = (e) =>
				e.clipboardData.setData('text/plain', copy_text)
				e.preventDefault()
				@wrapper.notifications.add "copy", "done", "Site address with peers copied to your clipboard", 5000
				document.removeEventListener('copy', handler, true)

			document.addEventListener('copy', handler, true)
			document.execCommand('copy')
			return false

		# Sign and publish content.json
		$(document).on "click touchend", =>
			@tag.find("#button-sign-publish-menu").removeClass("visible")
			@tag.find(".contents + .flex").removeClass("sign-publish-flex")

		@tag.find(".contents-content").on "click touchend", (e) =>
			$("#input-contents").val(e.currentTarget.innerText);
			return false;

		menu = new Menu(@tag.find("#menu-sign-publish"))
		menu.elem.css("margin-top", "-130px")  # Open upwards
		menu.addItem "Sign", =>
			inner_path = @tag.find("#input-contents").val()

			@wrapper.ws.cmd "fileRules", {inner_path: inner_path}, (rules) =>
				if @wrapper.site_info.auth_address in rules.signers
					# ZeroID or other ID provider
					@sign(inner_path)
				else if @wrapper.site_info.privatekey
					# Privatekey stored in users.json
					@sign(inner_path, "stored")
				else
					# Ask the user for privatekey
					@wrapper.displayPrompt "Enter your private key:", "password", "Sign", "", (privatekey) => # Prompt the private key
						@sign(inner_path, privatekey)

			@tag.find(".contents + .flex").removeClass "active"
			menu.hide()

		menu.addItem "Publish", =>
			inner_path = @tag.find("#input-contents").val()
			@wrapper.ws.cmd "sitePublish", {"inner_path": inner_path, "sign": false}

			@tag.find(".contents + .flex").removeClass "active"
			menu.hide()

		@tag.find("#menu-sign-publish").on "click touchend", =>
			if window.visible_menu == menu
				@tag.find(".contents + .flex").removeClass "active"
				menu.hide()
			else
				@tag.find(".contents + .flex").addClass "active"
				@tag.find(".content-wrapper").prop "scrollTop", 10000
				menu.show()
			return false

		$("body").on "click", =>
			if @tag
				@tag.find(".contents + .flex").removeClass "active"

		@tag.find("#button-sign-publish").on "click touchend", =>
			inner_path = @tag.find("#input-contents").val()

			@wrapper.ws.cmd "fileRules", {inner_path: inner_path}, (rules) =>
				if @wrapper.site_info.auth_address in rules.signers
					# ZeroID or other ID provider
					@publish(inner_path, null)
				else if @wrapper.site_info.privatekey
					# Privatekey stored in users.json
					@publish(inner_path, "stored")
				else
					# Ask the user for privatekey
					@wrapper.displayPrompt "Enter your private key:", "password", "Sign", "", (privatekey) => # Prompt the private key
						@publish(inner_path, privatekey)
			return false

		# Save and forget privatekey for site signing
		$(tag).find("#privatekey-add").on "click touchend", (e) =>
			@wrapper.displayPrompt "Enter your private key:", "password", "Save", "", (privatekey) =>
				@wrapper.ws.cmd "userSetSitePrivatekey", [privatekey], (res) =>
					@wrapper.notifications.add "privatekey", "done", "Private key saved for site signing", 5000
			return false

		$(tag).find("#privatekey-forget").on "click touchend", (e) =>
			@wrapper.displayConfirm "Remove saved private key for this site?", "Forget", (res) =>
				if not res
					return false
				@wrapper.ws.cmd "userSetSitePrivatekey", [""], (res) =>
					@wrapper.notifications.add "privatekey", "done", "Saved private key removed", 5000
			return false

		@loadGlobe()


window.Sidebar = Sidebar