require 'spec_helper'

# Testing out difference between let and before
describe "test difference between let and before" do
  let(:foo) do
    1
  end

  before do
    @bar = 2
  end

  it { foo.should eq(1) }


  it {foo.should eq(1)}
  it {@bar.should == 2}
  it {@bar.should eq(2) }
end