# frozen_string_literal: true

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

Gem::Specification.new do |s|
  s.name        = 'activerecord_aad'
  s.version     = '0.2.1'
  s.authors     = ['Taylor Yelverton']
  s.email       = 'rubygems@yelvert.io'
  s.homepage    = 'https://github.com/ComplyMD/activerecord_aad'
  s.summary     = ''
  s.license     = 'MIT'
  s.description = ''
  s.metadata    = {
    'bug_tracker_uri' => 'https://github.com/ComplyMD/activerecord_aad/issues',
    'changelog_uri' => 'https://github.com/ComplyMD/activerecord_aad/commits/master',
    'documentation_uri' => 'https://github.com/ComplyMD/activerecord_aad/wiki',
    'homepage_uri' => 'https://github.com/ComplyMD/activerecord_aad',
    'source_code_uri' => 'https://github.com/ComplyMD/activerecord_aad',
    'rubygems_mfa_required' => 'true',
  }

  s.files = Dir['lib/**/*', 'README.md', 'LICENSE', 'activerecord_aad.gemspec']

  s.require_paths = %w[ lib ]

  s.required_ruby_version = '>= 2.7.0'

  s.add_dependency('activerecord', '>= 6.0.0', '< 8.0.0')
  s.add_dependency('httparty', '~> 0.21.0')
end
