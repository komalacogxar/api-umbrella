Admin.AdminGroup = Ember.Model.extend({
  id: Ember.attr(),
  name: Ember.attr(),
  apiScopeIds: Ember.attr(),
  permissionIds: Ember.attr(),
  createdAt: Ember.attr(),
  updatedAt: Ember.attr(),
  creator: Ember.attr(),
  updater: Ember.attr(),
});

Admin.AdminGroup.url = '/api-umbrella/v1/admin_groups';
Admin.AdminGroup.rootKey = 'admin_group';
Admin.AdminGroup.collectionKey = 'data';
Admin.AdminGroup.primaryKey = 'id';
Admin.AdminGroup.camelizeKeys = true;
Admin.AdminGroup.adapter = Admin.APIUmbrellaRESTAdapter.create();
