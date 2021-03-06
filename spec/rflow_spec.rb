require 'spec_helper.rb'

require 'open3'
require 'rflow'

describe RFlow do

  before(:all) do
    @extensions_file_name = File.join(File.dirname(__FILE__), 'fixtures', 'extensions_ints.rb')
  end

#   context "when executing from the test script" do
#
#     before(:all) do
#       load @extensions_file_name
#     end
#
#     describe '.run' do
#       before(:each) do
#         @original_directory_path = Dir.getwd
#         @run_directory_path = File.join(@temp_directory_path, 'run')
#         @log_directory_path = File.join(@temp_directory_path, 'log')
#         Dir.mkdir @run_directory_path
#         Dir.mkdir @log_directory_path
#       end
#
#       after(:each) do
#         Dir.chdir @original_directory_path
#       end
#
#       def run_rflow_with_dsl(&block)
#         rflow_thread = Thread.new do
#           ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
#           RFlow::Configuration.migrate_database
#           RFlow::Configuration::RubyDSL.configure do |c|
#             block.call(c)
#           end
#
#           RFlow::Configuration.merge_defaults!
#
#           RFlow.run nil, false
#         end
#
#         # TODO: figure out a way to get rid of this sleep, as there
#         # should be a better way to figure out when RFlow is done
#         sleep(5)
#
#         # Shut down the reactor and the thread
#         EM.run { EM.stop }
#         rflow_thread.join
#       end
#
#
#       it "should run a non-sharded workflow" do
#
#         run_rflow_with_dsl do |c|
#           c.setting('rflow.log_level', 'DEBUG')
#           c.setting('rflow.application_directory_path', @temp_directory_path)
#           c.setting('rflow.application_name', 'nonsharded_test')
#
#           c.component 'generate_ints', 'RFlow::Components::GenerateIntegerSequence', 'start' => 20, 'finish' => 30
#           c.component 'output', 'RFlow::Components::FileOutput', 'output_file_path' => 'out'
#           c.component 'output2', 'RFlow::Components::FileOutput', 'output_file_path' => 'out2'
#           c.component 'output_even', 'RFlow::Components::FileOutput', 'output_file_path' => 'out_even'
#           c.component 'output_odd', 'RFlow::Components::FileOutput', 'output_file_path' => 'out_odd'
#           c.component 'output_even_odd', 'RFlow::Components::FileOutput', 'output_file_path' => 'out_even_odd'
#           c.component 'generate_ints2', 'RFlow::Components::GenerateIntegerSequence', 'start' => 20, 'finish' => 30
#           c.component 'output_even_odd2', 'RFlow::Components::FileOutput', 'output_file_path' => 'out_even_odd2'
#
#           c.connect 'generate_ints#out' => 'output#in'
#           c.connect 'generate_ints#out' => 'output2#in'
#           c.connect 'generate_ints#even_odd_out[even]' => 'output_even#in'
#           c.connect 'generate_ints#even_odd_out[odd]' => 'output_odd#in'
#           c.connect 'generate_ints#even_odd_out' => 'output_even_odd#in'
#           c.connect 'generate_ints2#even_odd_out' => 'output_even_odd2#in'
#         end
#
#         RFlow.master.shards.count.should == 1
#         RFlow.master.shards.first.workers.count.should == 1
#
#         output_files = {
#           'out'           => [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
#           'out2'          => [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
#           'out_even'      => [20, 22, 24, 26, 28, 30],
#           'out_odd'       => [21, 23, 25, 27, 29],
#           'out_even_odd'  => [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
#           'out_even_odd2' => [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
#         }
#
#         output_files.each do |file_name, expected_contents|
#           File.exist?(File.join(@temp_directory_path, file_name)).should be_true
#           File.readlines(file_name).map(&:to_i).should == expected_contents
#         end
#       end
#
#
#       it "should run a sharded workflow" do
#         run_rflow_with_dsl do |c|
#           c.setting('rflow.log_level', 'DEBUG')
#           c.setting('rflow.application_directory_path', @temp_directory_path)
#           c.setting('rflow.application_name', 'sharded_test')
#
#           # Instantiate components
#           c.shard 's1', :process => 3 do |s|
#             s.component 'generate_ints1', 'RFlow::Components::GenerateIntegerSequence', 'start' => 0, 'finish' => 10, 'step' => 3
#           end
#
#           c.shard 's2', :type => :process, :count => 2 do |s|
#             s.component 'generate_ints2', 'RFlow::Components::GenerateIntegerSequence', 'start' => 20, 'finish' => 30
#           end
#
#           c.component 'generate_ints3', 'RFlow::Components::GenerateIntegerSequence', 'start' => 100, 'finish' => 105
#
#           c.shard 's3', :process => 2 do |s|
#             s.component 'output1', 'RFlow::Components::FileOutput', 'output_file_path' => 'out1'
#             s.component 'output2', 'RFlow::Components::FileOutput', 'output_file_path' => 'out2'
#           end
#
#           c.component 'output3', 'RFlow::Components::FileOutput', 'output_file_path' => 'out3'
#           c.component 'output_all', 'RFlow::Components::FileOutput', 'output_file_path' => 'out_all'
#
#           # Hook components together
#           c.connect 'generate_ints1#out' => 'output1#in'
#           c.connect 'generate_ints2#out' => 'output2#in'
#           c.connect 'generate_ints3#out' => 'output3#in'
#           c.connect 'generate_ints1#out' => 'output_all#in'
#           c.connect 'generate_ints2#out' => 'output_all#in'
#           c.connect 'generate_ints3#out' => 'output_all#in'
#         end
#
#         RFlow.master.shards.count.should == 4
#         RFlow.master.shards.map(&:count).should == [1, 3, 2, 2]
#         RFlow.master.shards.map(&:workers).map(&:count).should == [1, 3, 2, 2]
#
#         output_files = {
#           'out1'    => [0, 3, 6, 9] * 3,
#           'out2'    => (20..30).to_a * 2,
#           'out3'    => (100..105).to_a,
#           'out_all' => [0, 3, 6, 9] * 3 + (20..30).to_a * 2 + (100..105).to_a
#         }
#
#         output_files.each do |file_name, expected_contents|
#           File.exist?(File.join(@temp_directory_path, file_name)).should be_true
#           File.readlines(file_name).map(&:to_i).sort.should == expected_contents.sort
#         end
#       end
#     end
#   end

  context "when executing via the rflow binary" do
    before(:each) do
      @original_directory_path = Dir.getwd
      @run_directory_path = File.join(@temp_directory_path, 'run')
      @log_directory_path = File.join(@temp_directory_path, 'log')
      Dir.mkdir @run_directory_path
      Dir.mkdir @log_directory_path
      Dir.chdir @temp_directory_path
    end

    after(:each) do
      Dir.chdir @original_directory_path
    end

    def execute_rflow(rflow_args)
      r = {}
      r[:stdout], r[:stderr], r[:status] = Open3.capture3("bundle exec rflow #{rflow_args}")
      r
    end

    context "with a simple ruby DSL config file" do
      before(:each) do
        @config_file_name = 'input_config'
        File.open('input_config', 'w+') do |file|
          file.write <<-EOF
            RFlow::Configuration::RubyDSL.configure do |c|
              c.setting 'mysetting', 'myvalue'
            end
          EOF
        end
      end

      it "should load a ruby dsl file into a sqlite DB" do
        db_file_name = 'outdb'

        r = execute_rflow("load -d #{db_file_name} -c #{@config_file_name}")

        # Make sure that the process execution worked
        r[:status].exitstatus.should == 0
        r[:stderr].should == ''
        r[:stdout].should match /Successfully initialized database.*#{db_file_name}/

        # Make sure the config actually got loaded
        ActiveRecord::Base.establish_connection adapter: "sqlite3", database: db_file_name
        RFlow::Configuration::Setting.where(:name => 'mysetting').first.value.should == 'myvalue'
      end

      it "should not load a database if the database file already exists" do
        db_file_name = 'outdb'
        File.open(db_file_name, 'w') { |file| file.write 'boom' }

        r = execute_rflow("load -d #{db_file_name} -c #{@config_file_name}")

        # Make sure that the process execution worked
        r[:status].exitstatus.should == 1
        r[:stderr].should == ''
        r[:stdout].should match /Config database.*#{db_file_name}.*exists/
      end

    end

    context "with a complex, sharded ruby DSL config file" do
      before(:each) do
        @config_file_name = 'input_config'
        @db_file_name = 'config_db'
        @app_name = 'sharded_bin_test'
        File.open(@config_file_name, 'w+') do |file|
          file.write <<-EOF
            RFlow::Configuration::RubyDSL.configure do |c|
              c.setting('rflow.log_level', 'INFO')
              c.setting('rflow.application_directory_path', '#{@temp_directory_path}')
              c.setting('rflow.application_name', '#{@app_name}')
              # Instantiate components
              c.shard 's1', :process => 3 do |s|
                s.component 'generate_ints1', 'RFlow::Components::GenerateIntegerSequence', 'start' => 0, 'finish' => 10, 'step' => 3
              end
              c.shard 's2', :type => :process, :count => 2 do |s|
                s.component 'generate_ints2', 'RFlow::Components::GenerateIntegerSequence', 'start' => 20, 'finish' => 30
              end
              c.component 'generate_ints3', 'RFlow::Components::GenerateIntegerSequence', 'start' => 100, 'finish' => 105
              c.shard 's3', :process => 2 do |s|
                s.component 'output1', 'RFlow::Components::FileOutput', 'output_file_path' => 'out1'
                s.component 'output2', 'RFlow::Components::FileOutput', 'output_file_path' => 'out2'
              end
              c.component 'output3', 'RFlow::Components::FileOutput', 'output_file_path' => 'out3'
              c.component 'output_all', 'RFlow::Components::FileOutput', 'output_file_path' => 'out_all'
              # Hook components together
              c.connect 'generate_ints1#out' => 'output1#in'
              c.connect 'generate_ints2#out' => 'output2#in'
              c.connect 'generate_ints3#out' => 'output3#in'
              c.connect 'generate_ints1#out' => 'output_all#in'
              c.connect 'generate_ints2#out' => 'output_all#in'
              c.connect 'generate_ints3#out' => 'output_all#in'
            end
          EOF
        end
        r = execute_rflow("load -d #{@db_file_name} -c #{@config_file_name}")
        r[:status].exitstatus.should == 0
        r[:stderr].should == ''
        r[:stdout].should match /Successfully initialized database.*#{@db_file_name}/
      end

      it "should not start if the components aren't loaded" do
        r = execute_rflow("start -d #{@db_file_name} -f")

        r[:status].exitstatus.should == 1
        r[:stderr].should == ''
        r[:stdout].should match /error/i
      end

      it "should daemonize and run in the background" do
        r = execute_rflow("start -d #{@db_file_name} -e #{@extensions_file_name}")

        r[:status].exitstatus.should == 0
        r[:stderr].should == ''
        r[:stdout].should_not match /error/i

        sleep 1 # give the daemon a chance to finish

        log_contents = File.read("log/#{@app_name}.log").chomp
        log_lines = log_contents.split("\n")

        puts '++++++++++++++++++++'
        puts log_contents
        puts '++++++++++++++++++++'

        # Log file testing
        log_lines.each { |line| line.should_not match /^ERROR/ }
        log_lines.each { |line| line.should_not match /^DEBUG/ }

        # Grab all the pids from the log, which seems to be the only
        # reliable way to get them
        log_pids = log_lines.map { |line| /\((\d+)\)/.match(line)[1].to_i }.uniq

        initial_pid = r[:status].pid
        master_pid = File.read("run/#{@app_name}.pid").chomp.to_i
        worker_pids = log_pids - [initial_pid, master_pid]

        log_pids.should include initial_pid
        log_pids.should include master_pid

        worker_pids.size.should == 8
        worker_pids.should_not include 0

        # Process checks
        expect { Process.kill(0, initial_pid) }.to raise_error(Errno::ESRCH)
        ([master_pid] + worker_pids).each do |pid|
          Process.kill(0, pid).should == 1
        end

        # Output checks
        output_files = {
          'out1'    => [0, 3, 6, 9] * 3,
          'out2'    => (20..30).to_a * 2,
          'out3'    => (100..105).to_a,
          'out_all' => [0, 3, 6, 9] * 3 + (20..30).to_a * 2 + (100..105).to_a
        }

        output_files.each do |file_name, expected_contents|
          File.exist?(File.join(@temp_directory_path, file_name)).should be_true
          File.readlines(file_name).map(&:to_i).sort.should == expected_contents.sort
        end

        # Terminate the master
        Process.kill("TERM", master_pid).should == 1

        # Make sure everything is dead after a second
        sleep 1
        ([master_pid] + worker_pids).each do |pid|
          expect { Process.kill(0, pid) }.to raise_error(Errno::ESRCH)
        end
      end
    end
  end
end
