import pytest
import json
from Config import config
from User import UserManager

@pytest.mark.usefixtures("resetSettings")
@pytest.mark.usefixtures("resetTempSettings")
class TestMultiuser:
    def testMemorySave(self, user):
        # It should not write users to disk
        with open("%s/users.json" % config.data_dir) as f:
            users_before = f.read()
        user = UserManager.user_manager.create()
        user.save()
        with open("%s/users.json" % config.data_dir) as f:
            assert f.read() == users_before
