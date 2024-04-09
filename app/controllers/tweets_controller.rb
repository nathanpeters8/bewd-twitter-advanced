class TweetsController < ApplicationController
  def index
    @tweets = Tweet.all.order(created_at: :desc)
    render 'tweets/index'
  end

  def create
    token = cookies.signed[:twitter_session_token]
    session = Session.find_by(token: token)
    user = session.user

    # user.tweets count in past 60 minutes should be less than 30
    if user.tweets.where('created_at > ?', Time.now - 60.minutes).count < 30
      @tweet = user.tweets.new(tweet_params)
      if @tweet.save
        # send an email to the user when a tweet is posted
        TweetMailer.notify(@tweet).deliver! 
        render 'tweets/create'
      end
    else
      return render json: {
        error: {
          message: 'Rate limit exceeded (30 tweets/hour). Please try again later.'
        }
      }
    end
  end

  def destroy
    token = cookies.signed[:twitter_session_token]
    session = Session.find_by(token: token)

    return render json: { success: false } unless session

    user = session.user
    tweet = Tweet.find_by(id: params[:id])

    if tweet && (tweet.user == user) && tweet.destroy
      render json: {
        success: true
      }
    else
      render json: {
        success: false
      }
    end
  end

  def index_by_user
    user = User.find_by(username: params[:username])

    if user
      @tweets = user.tweets
      render 'tweets/index'
    end
  end

  private

  def tweet_params
    params.require(:tweet).permit(:message, :image)
  end
end
