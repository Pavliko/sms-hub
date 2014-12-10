worker_processes 1
timeout 30

@app_path = '%%{deploy_to}/%%{current_path}'
listen "#{@app_path}/tmp/sockets/unicorn.sock", :backlog => 64
pid "#{@app_path}/tmp/pids/unicorn.pid"
stderr_path "#{@app_path}/log/unicorn.stderr.log"
stdout_path "#{@app_path}/log/unicorn.stdout.log"
