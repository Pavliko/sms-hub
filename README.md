# To run project:

```
cp config/deploy_config.example.rb  config/deploy_config.rb
```
Fill your data into config.

Run next command and follow the instructions.
```
bundle install
bundle exec mina setup
bundle exec mina deploy setup_finish
```

 TEST request
```
curl -D - -X POST http://localhost:3000/pull -F "from=" -F "message=sample text message" -F "=123456"
```
