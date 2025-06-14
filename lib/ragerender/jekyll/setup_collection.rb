def setup_collection site, label, permalink, **kwargs
  site.config['collections'][label.to_s] = {
    'output' => true,
    'permalink' => permalink,
    'sort_by' => 'date',
  }

  site.config['defaults'].prepend({
    'scope' => {
      'path' => '',
      'type' => label.to_s,
    },
    'values' => {
      'permalink' => permalink,
      **kwargs.map do |k, v|
        [k.to_s, v]
      end.to_h,
    },
  })
end
