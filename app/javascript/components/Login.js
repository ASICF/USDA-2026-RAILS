import React, { useState, Fragment } from "react";
import {
  Button,
  Form,
  Grid,
  Header,
  Image,
  Message,
  Icon,
  Divider,
  Segment,
  ButtonContent,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";
import "./Styles/default";

export default function Login(props) {
  const [form, setForm] = useState("login");

  return (
    <Grid
      textAlign="center"
      style={{
        // height: "100vh",
        marginTop: "2em",
      }}
      verticalAlign="middle"
    >
      <Grid.Column style={{ maxWidth: 450 }}>
        {form === "login" ? loginForm() : resetForm()}
      </Grid.Column>
    </Grid>
  );

  function loginForm() {
    return (
      <Fragment>
        <Header as="h2" textAlign="center">
          Login to your account
        </Header>
        <Form
          size="large"
          action="/users/sign_in"
          // acceptCharset="UTF-8"
          method="post"
        >
          <Segment stacked>
            <input
              type="hidden"
              name="authenticity_token"
              value={props.token}
            />
            <input type="hidden" name="user[remember_me]" value={"1"} />
            <Form.Input
              fluid
              icon="user"
              iconPosition="left"
              placeholder="E-mail address"
              name="user[email]"
            />
            <Form.Input
              fluid
              icon="lock"
              iconPosition="left"
              placeholder="Password"
              type="password"
              name="user[password]"
            />
            <Button primary animated fluid size="large">
              <ButtonContent visible>Login</ButtonContent>
              <ButtonContent hidden>
                <Icon name="arrow right" />
              </ButtonContent>
            </Button>
            <Divider />
            <Header
              as="h5"
              style={{ cursor: "pointer" }}
              onClick={() => setForm("reset")}
            >
              Forgot Password?
            </Header>
          </Segment>
        </Form>
      </Fragment>
    );
  }

  function resetForm() {
    return (
      <Fragment>
        <Header as="h2" textAlign="center">
          It happens.
        </Header>
        <Form size="large" action="/users/password" method="post">
          <Segment stacked>
            <input
              type="hidden"
              name="authenticity_token"
              value={props.token}
            />
            <Form.Input
              fluid
              icon="user"
              iconPosition="left"
              placeholder="E-mail address"
              name="user[email]"
            />
            <Button positive animated fluid size="large">
              <ButtonContent visible>
                Send me Password reset instructions
              </ButtonContent>
              <ButtonContent hidden>
                <Icon name="check circle" />
              </ButtonContent>
            </Button>
            <Divider />
            <Header
              as="h5"
              style={{ cursor: "pointer" }}
              onClick={() => setForm("login")}
            >
              Nevermind, I remember my Password
            </Header>
          </Segment>
        </Form>
      </Fragment>
    );
  }
}
