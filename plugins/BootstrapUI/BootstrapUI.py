import io
import os

from Plugin import PluginManager
from Config import config
from Translate import Translate
from util.Flag import flag


plugin_dir = os.path.dirname(__file__)

if "_" not in locals():
    _ = Translate(plugin_dir + "/languages/")


@PluginManager.registerTo("UiRequest")
class UiRequestPlugin(object):
    def actionWrapper(self, path, extra_headers=None):
        if path.strip("/") != "zeronet-bootstrap":
            return super(UiRequestPlugin, self).actionWrapper(path, extra_headers)
        return self.actionUiMedia("/uimedia/plugins/bootstrapui/index.html")

    def actionUiMedia(self, path, *args, **kwargs):
        if path.startswith("/uimedia/plugins/bootstrapui/"):
            file_path = path.replace("/uimedia/plugins/bootstrapui/", plugin_dir + "/media/")
            if config.debug and (file_path.endswith("all.js") or file_path.endswith("all.css")):
                # If debugging merge *.css to all.css and *.js to all.js
                from Debug import DebugMedia
                DebugMedia.merge(file_path)

            if file_path.endswith("js"):
                data = _.translateData(open(file_path).read(), mode="js").encode("utf8")
            elif file_path.endswith("html"):
                data = _.translateData(open(file_path).read(), mode="html").encode("utf8")
            else:
                data = open(file_path, "rb").read()

            return self.actionFile(file_path, file_obj=io.BytesIO(data), file_size=len(data))
        else:
            return super(UiRequestPlugin, self).actionUiMedia(path)
