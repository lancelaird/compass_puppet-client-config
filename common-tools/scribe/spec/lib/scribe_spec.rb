require 'rspec'

$: << '../../lib'

require 'scribe'

describe "Scribe", fakefs: true do

  subject { Scribe.new }

  describe "Hiera" do

    it "ensures that a given statement is added to Hiera config YAML" do
      given_file custom_yaml, config_with_no_capman

      expect do

        subject.
            ensure_presence_of(statement).
            in_hiera(custom_yaml)

      end.to change { the custom_yaml }.
        from(config_with_no_capman).
        to  (expected_config)
    end

    it "ensures that a given statement is updated in Hiera config YAML" do
      given_file custom_yaml, config_with_older_version_of_capman

      expect do

        subject.
            ensure_presence_of(statement).
            in_hiera(custom_yaml)

      end.to change { the custom_yaml }.
        from(config_with_older_version_of_capman).
        to  (expected_config)
    end

    let(:custom_yaml) { '/hiera-custom.yaml' }

    let(:statement) do
      { 'capman' => {
          'version'      => '0.0.1+build.168',
          'architecture' => 'x86_64',
          'tag'          => 'capman',
          'vendor'       => 'Thomson Reuters'
      }}
    end

    let(:config_with_no_capman) do
      <<-EOS.unindent
      ---
      packages:
        ems-kibana-addon:
          version: 0.1-17
          architecture: noarch
        ems-kibana-portal:
          version: 3-24
          architecture: noarch
        ems-logstash:
          version: 1.3.3-1
          architecture: noarch
      EOS
    end

    let(:config_with_older_version_of_capman) do
      <<-EOS.unindent
      ---
      packages:
        ems-kibana-addon:
          version: 0.1-17
          architecture: noarch
        ems-kibana-portal:
          version: 3-24
          architecture: noarch
        ems-logstash:
          version: 1.3.3-1
          architecture: noarch
        capman:
          version: 0.0.1+build.1
          architecture: x86_64
          tag: capman
      EOS
    end

    let(:expected_config) do
      <<-EOS.unindent
      ---
      packages:
        ems-kibana-addon:
          version: 0.1-17
          architecture: noarch
        ems-kibana-portal:
          version: 3-24
          architecture: noarch
        ems-logstash:
          version: 1.3.3-1
          architecture: noarch
        capman:
          version: 0.0.1+build.168
          architecture: x86_64
          tag: capman
          vendor: Thomson Reuters
      EOS
    end
  end

  describe 'Nolio' do
    let(:artifact) do
      {
          'url' => 'SAMI-BIN/Releases/Mount17/cpit_eikonmon/capman-0.0.1+build.173-1.x86_64.rpm',
          'md5' => '89dac68721203221e61b51a5b7869545'
      }
    end

    let(:config_xml) { '/eikonmon_client_release_manifest.xml' }

    it "updates nolio config XML with a release name and version" do
      given_file config_xml, config_with_no_capman

      expect do

        subject.
            update_nolio(config_xml, release_name: 'Eikonmon client 03.03.112', release_version: '10')

      end.to change { the config_xml }.
        from(config_with_no_capman).
        to  (expected_config_with_updated_release_name_and_version)
    end

    it "ensures that a given artifact is added to Nolio config XML" do
      given_file config_xml, config_with_no_capman

      expect do

        subject.ensure_presence_of(artifact).
        in_nolio(config_xml)

      end.to change { the config_xml }.
        from(config_with_no_capman).
        to  (expected_config)
    end

    it "ensures that a given artifact is updated in Nolio config XML" do
      given_file config_xml, config_with_older_version_of_capman

      expect do

        subject.
            ensure_presence_of(artifact).
            in_nolio(config_xml)

      end.to change { the config_xml }.
        from(config_with_older_version_of_capman).
        to  (expected_config)
    end

    it "ensures that a given artifact is updated in Nolio config XML preserving other attributes" do
      old_contents = config_with_older_version_of_capman_and_parameter_attribute

      given_file config_xml, old_contents

      # AW Test case for Compass puppet package
      expect do

        subject.
            ensure_presence_of(artifact).
            in_nolio(config_xml)

      end.to change { the config_xml }.
                 from(old_contents).
                 to  (expected_config_with_parameter_attribute)
    end

    let(:config_with_no_capman) do
      <<-EOS.unindent
      <?xml version="1.0" encoding="utf-8"?>
      <release name="Eikonmon client 02.02.34" version="1" type="Minor" format="2.0">
        <application>Eikonmon</application>
        <template>Eikonmon client 01.02.01</template>
        <server-type name="client">
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/Eikonmon-02.02.34.zip" md5="51d454d89d85316352489ecb94d2a682"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/puppet-01.01.12.rpm.zip" md5="84ff98c8e4108fe34a6cdad4ae212f7f"/>
        </server-type>
      </release>
      EOS
    end

    let(:expected_config_with_updated_release_name_and_version) do
      <<-EOS.unindent
      <?xml version="1.0" encoding="utf-8"?>
      <release name="Eikonmon client 03.03.112" version="10" type="Minor" format="2.0">
        <application>Eikonmon</application>
        <template>Eikonmon client 01.02.01</template>
        <server-type name="client">
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/Eikonmon-02.02.34.zip" md5="51d454d89d85316352489ecb94d2a682"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/puppet-01.01.12.rpm.zip" md5="84ff98c8e4108fe34a6cdad4ae212f7f"/>
        </server-type>
      </release>
      EOS
    end

    let(:config_with_older_version_of_capman) do
      <<-EOS.unindent
      <?xml version="1.0" encoding="utf-8"?>
      <release name="Eikonmon client 02.02.34" version="1" type="Minor" format="2.0">
        <application>Eikonmon</application>
        <template>Eikonmon client 01.02.01</template>
        <server-type name="client">
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/Eikonmon-02.02.34.zip" md5="51d454d89d85316352489ecb94d2a682"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/puppet-01.01.12.rpm.zip" md5="84ff98c8e4108fe34a6cdad4ae212f7f"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/capman-0.0.1+build.160-1.x86_64.rpm" md5="77722a036344b33bffdaef174978c0dd"/>
        </server-type>
      </release>
      EOS
    end

    let(:config_with_older_version_of_capman_and_parameter_attribute) do
      <<-EOS.unindent
      <?xml version="1.0" encoding="utf-8"?>
      <release name="Eikonmon client 02.02.34" version="1" type="Minor" format="2.0">
        <application>Eikonmon</application>
        <template>Eikonmon client 01.02.01</template>
        <server-type name="client">
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/Eikonmon-02.02.34.zip" md5="51d454d89d85316352489ecb94d2a682"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/puppet-01.01.12.rpm.zip" md5="84ff98c8e4108fe34a6cdad4ae212f7f"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/capman-0.0.1+build.160-1.x86_64.rpm" md5="77722a036344b33bffdaef174978c0dd" parameter="Compass/Puppet/Puppet Package"/>
        </server-type>
      </release>
      EOS
    end

    let(:expected_config) do
      <<-EOS.unindent
      <?xml version="1.0" encoding="utf-8"?>
      <release name="Eikonmon client 02.02.34" version="1" type="Minor" format="2.0">
        <application>Eikonmon</application>
        <template>Eikonmon client 01.02.01</template>
        <server-type name="client">
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/Eikonmon-02.02.34.zip" md5="51d454d89d85316352489ecb94d2a682"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/puppet-01.01.12.rpm.zip" md5="84ff98c8e4108fe34a6cdad4ae212f7f"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/capman-0.0.1+build.173-1.x86_64.rpm" md5="89dac68721203221e61b51a5b7869545"/>
        </server-type>
      </release>
      EOS
    end

    ##AW Actual case we need for Compass
    ## <artifact url="SAMI-BIN/Releases/Mount17/cpit_compass/puppet-package-1.0.10.auto-52.tar.gz" md5="7444f2f974fce7989f7795e08128b3ed" parameter="Compass/Puppet/Puppet Package"/>
    let(:expected_config_with_parameter_attribute) do
      <<-EOS.unindent
      <?xml version="1.0" encoding="utf-8"?>
      <release name="Eikonmon client 02.02.34" version="1" type="Minor" format="2.0">
        <application>Eikonmon</application>
        <template>Eikonmon client 01.02.01</template>
        <server-type name="client">
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/Eikonmon-02.02.34.zip" md5="51d454d89d85316352489ecb94d2a682"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/puppet-01.01.12.rpm.zip" md5="84ff98c8e4108fe34a6cdad4ae212f7f"/>
          <artifact url="SAMI-BIN/Releases/Mount17/cpit_eikonmon/capman-0.0.1+build.173-1.x86_64.rpm" md5="89dac68721203221e61b51a5b7869545" parameter="Compass/Puppet/Puppet Package"/>
        </server-type>
      </release>
      EOS
    end
  end

  def given_file name, contents
    File.open(name, 'w') { | f | f.write(contents) }
  end

  def the config_file
    return File.read(config_file)
  end
end
