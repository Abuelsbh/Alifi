/// Entry path from the nav bar or list screens — controls which sub-types appear in step 1.
enum AddAnimalFlow {
  /// Dropdown: مفقود / تم العثور عليه
  lostOrFound,

  /// Dropdown: أنا بدي حيوان للتبني / أنا بدي أحد يتبني حيواني
  adoption,

  /// No sub-type dropdown; report is breeding.
  breeding,
}
