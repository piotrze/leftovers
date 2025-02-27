# v0.11.1
- Fixed an issue with parsing files that have `MyConstant ||= value` patterns #19 (thanks for the pr - @kamoh)

# v0.11.0
- Fixed an issue with active_record's `before_save` with multiple callbacks #18, #17 - thanks @palexvs for raising the issue and creating a pr
- Due to this pr, i reviewed everything else that i think calls `ActiveSupport::Callbacks.set_callback`, and ensured they all:
  - can have multiple args if relevant
  - accept single values and array values for the if/unless args
  - don't eval strings, that's not been a rails feature for a while
- Fix active_model & active_record validation methods to more comprehensively handle all the keys that could be given symbols of method names, instead of only the documented ones

# v0.10.0
- Fixed an issue with t.belongs_to (within the migration generated by rails active_storage:install - thanks @veganstraightedge)
  - this was two issues:
    1. it was raising an error because the DefinitionNode didn't act enough like an AST::Node, now it does
    2. this should never have been defining anything anyway as the activerecord method was being assumed to be used, now if there's an explicit receiver for belongs_to/has_many etc, don't consider them the active record association methods.

- now `has_receiver: true` and `has_receiver: false/nil` act differently, they refer to the presence or absence of any receiver, instead of the receiver being literally true or false or nil.
- to have the previous behaviour, use the new `has_receiver: { literal: true }` or `literal: false` or `literal: null`

# v0.9.0
- Automatically test the config examples in the documentation, and fix the errors
- simplify the `type: Proc` matcher
- Update FastIgnore dependency, make fewer filesystem calls
- Comprehensively describe all of ruby core and rails
  This required/revealed a number of additions to the config
  - Improve the performance of large config files by squash the config matching more
  - Add `names:` and `has_arguments:` to `has_value:`.
  - Fix error when positional `has_arguments:`/`has_value: at:` checks a node without arguments
  - Add `eval` as a processing type, alongside `calls:` and `defines:`, this will process allow processing literal calls to instance_eval etc.
  - Allow calling or defining based on the `receiver:`
  - `all: []` & `any: []` arguments to dynamic/keep/test_only
  - add `arguments: 1+` or `has_arguments: { at: 1+, has_value: true }` to match arguments from that position onward
  - allow `has_arguments:` and `has_receiver:` (and `unless:` and `all:` and `any:` of those) to go within `calls:`,`defines:`,`set_privacy:`,`add_prefix:`,`add_suffix:` for cases like the `delegate prefix: true` vs `delegate prefix: :value` without having to redefine everything.
  - allow `has_arguments.at` and `arguments:` to have a `type:` to distinguish between e.g. symbol keys and string keys.
- Add a way to test custom precompilers with --view-compiled [PATH_PATTERNS...]

# v0.8.0
- Allow custom precompilers
  ```yml
    require: './path/to/my_precompiler'
    precompile:
      - paths: '*.myCustomFormat'
        format: { custom: 'MyPrecompiler' }
  ```
  the built in precompilers have moved into this system too, with `format: haml` etc. `haml_paths` etc are now deprecated
- a lot of refactoring, which revealed some edge cases i was handling
  - collect a call to :my_method= with receiver&.my_method ||= (and += etc)
  - if `add_prefix:` or `add_suffix:` points to another argument for a name that we can't use because it's a variable, it now just don't return the value, rather than returning the value but without the affix

# v0.7.0
- Rewrite the config parser/validation
  - to provide clearer error messages with line numbers and everything
  - to allow removing the json_schemer dependency with its 4 further dependencies
- Allow `match:` to be used with `has_prefix:` and/or `has_suffix:`. There's not a good use for this but it was easier than encoding 'this can't be used with that' logic especially for it.
- Add the possibility to quiet the `requires:` config, like:
  ```yml
  requires:
  - 'active_support/inflections'
  - quiet: './config/initializers/inflections'
  ```
- consider all the public methods in rails custom generators to be used, this required some new features:
  - add filtering methods/constants by public/protected/private
  - add the possibility to set the privacy of methods and constants with method calls (`set_privacy:`, and `set_default_privacy:`)
  - add `Method` and `Constant` as options for the `type:` filter
  - add type filtering to dynamic.
- check `def self.whatever` as a definition, i didn't realise i wasn't checking this.

# v0.6.0
- drop ruby 2.4 support, allowing for some performance improvements
- Add ability to parse JSON and YAML files
- Add magic comment that points to a particular dynamic rule
- repeated calls to --write-todo won't have ordering differences
- fix issue with --write-todo and unused methods defined in test files

# v0.5.5
- Fix rails resource/resources method signatures

# v0.5.4
- Add support for slim templates #13 - thanks @veganstraightedge
- fix the #how-to-resolve link #11 - thanks @veganstraightedge

# v0.5.3
- fix incompatibility with activesupport 7.

# v0.5.2
- allow config entries to have duplicates (especially as --write-todo) can write a file with duplicates)

# v0.5.1
- fixed a bug with the erb parsing where it was incorrectly compiling comments:
```
<% # Comment %>
<% if query? %>
  <%= content %>
<% end %>
```

# v0.5.0
- `has_receiver:` will match the receiver for methods and the namespace for constants.
- `has_value_type:` is now `has_value: type:`
- `has_value:` can be nested with `at:` and `has_value:`.
- `has_argument:` can be given `at:` with `'*'` or `'**'` which matches all positional arguments or keyword arguments respectively
- the rails.yml config has been broken up into e.g. activerecord, actionpack, etc
- `haml_paths:` and `erb_paths:` are now configurable.
- `type:` can match on `'Array'`, `'Hash'`, and `'Proc'` literals.
- rails.yml config determines which `scope` is which by its shape rather than its path: (ActiveRecord#scope has a proc as the second parameter)
- `--write--todo` now correctly handles grouped definitions (like activemodel attributes)

# v0.4.4
- don't hard-wrap the --write-todo instructions it looks weird

# v0.4.3
- add --write-todo so you can add this to your project without
immediately fixing everything.

# v0.4.2
- Make sorbet happy with this as a dependency
# v0.4.1
- add `test_only:` to mark methods/constants/assignments as test_only in the config rather than just with magic comments

# v0.4.0
- add `requires:` to .leftovers.yml config to e.g. load inflections in a different place than `config/initializers/inflections`
- REFACTORED EVERYTHING for a codebase i actually can extend
- Now with a very modified config api. After this i don't intend on every doing a rewrite like this again, so this is correcting all my bad decisions the first time through
  - `rules.names` with `rules.skip: true` is now `keep.names` (see config/parser.yml)
  - `rules.calls` and `rules.defines` is now `dynamic.calls` and `dynamic.defines`
  - `rules.calls/defines.arguments.if` is now `keep/dynamic.calls/defines.has_arguments:` (see config/graphql.yml field)
  - `rules.calls/defines.arguments.unless` is now `keep/dynamic.unless.has_arguments` (see config/graphql.yml field)
  - `rules.calls/defines.transforms.replace_with` is now `keep/dynamic.calls/defines.value` (see custom_config_spec.rb html)
  - `rules.calls/defines.transforms.add_prefix.from_argument/joiner:` is now `dynamic.calls/defines.transforms.add_prefix.argument/add_suffix` (see config/rails.yml delegate)
  - `rules.calls/defines.transforms.add_suffix.from_argument/joiner:` is now `dynamic.calls/defines.transforms.add_suffix.argument/add_prefix`
  - `rules.calls/defines.key: true` is now `dynamic.calls/defines.keywords: '**'`
  - `rules.calls/defines.arguments.if.arguments.value` is now `keep/dynamic.has_arguments.has_value`
  - `rules.calls/defines.arguments.if.arguments.value.type` is now `keep/dynamic.has_arguments.has_value_type`
  - `rules.calls/defines.linked_transforms` is now `dynamic.calls/defines.transforms` (see config/rails.yml attribute). For the previous behaviour of the `transforms:` key simply add separate calls/defines entry. (see config/ruby.yml attr_accessor)
  - `rules.calls/defines.keys: true` is now `dynamic.calls/defines.keywords: '**'` and can be given name patterns (e.g. unless:. see config/rails.yml validates)
  - argument positions are now 0-indexed rather than 1-indexed
  - no more automatic recursion, there's now two new keywords:
    - `dynamic.calls/defines.arguments/keywords` with `dynamic.calls/defines.nested.arguments/keywords` will define the next layer of arguments to collect (see config/rails.yml validates)
    - `dynamic.calls/defines.arguments/keywords` with `dynamic.calls/defines.recursive: true` will use the arguments & keywords layers recursively (see config/rails.yml permit)
  - no more automatic splitting on ':' and '.', there's now a `dynamic.calls/defines.transforms.split: '::'` (see config/rails.yml resource)

# v0.3.0
- Add simplecov, fix a handful of bugs it found
- update fast_ignore

# v0.2.4
- use the right name for selenium-webdriver gem, so the bundler magic can work
- handle yaml syntax errors.

# v0.2.3
- restore ability to handle syntax errors. I really need to add coverage to this project
- Fix bug with delete_after on an empty string
- Support more of rails
- Support parts of sidekiq

# v0.2.2
- update fast_ignore dependency

# v0.2.1

- Fix route arguments with '/' handling (e.g get `'/admin', to: 'admin/dashboard#index'`)
- Fix route arguments for `root to: "whatever#index"`
- Add some more rails exceptions (`APP_ROOT`, `APP_PATH`, Mailer Previews)
- add more ruby object methods that are called by various bits of ruby
- correct output of unused definitions using `linked_transforms:`
- add `audited` gem

# v0.2.0

Play nice with rubocop

# v0.1.0

Initial release
